#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "native_crypto.h" // Our own header file.
#include "sodium.h" // The main header from the libsodium library.

// This is the implementation of the function we declared in the header.
const char* get_libsodium_version_string() {
    // It's mandatory to initialize libsodium before using any other function.
    // It's safe to call this function multiple times.
    if (sodium_init() < 0) {
        // If initialization fails, we return an error message.
        return "libsodium initialization failed";
    }

    // This function from libsodium returns its version string.
    return sodium_version_string();
}
//we use the maximum limits for the password hash
int hash_password(char *hashed_password, const char *password) {
    if (crypto_pwhash_str(hashed_password, password, strlen(password),
                          crypto_pwhash_OPSLIMIT_SENSITIVE, crypto_pwhash_MEMLIMIT_SENSITIVE) != 0) {
        return -1; // Error
    }
    return 0; // Success
}

int verify_password(const char *hashed_password, const char *password) {
    if (crypto_pwhash_str_verify(hashed_password, password, strlen(password)) != 0) {
        // Wrong password
        return -1;
    }
    // Correct password
    return 0;
}

void free_string(char* str) {
    if (str != NULL) {
        free(str);
    }
}

// Helper: base64 encode using libsodium, returns malloc'd string
static char* _bin_to_b64(const unsigned char* bin, size_t bin_len) {
    size_t b64_len = sodium_base64_ENCODED_LEN(bin_len, sodium_base64_VARIANT_ORIGINAL);
    char* b64 = malloc(b64_len);
    if (b64 == NULL) return NULL;
    sodium_bin2base64(b64, b64_len, bin, bin_len, sodium_base64_VARIANT_ORIGINAL);
    return b64;
}

// Helper: decode base64 -> bin (malloc)
static unsigned char* _b64_to_bin(const char* b64, size_t* out_len) {
    size_t max_len = strlen(b64) * 3 / 4 + 1;
    unsigned char* bin = malloc(max_len);
    if (bin == NULL) return NULL;
    if (sodium_base642bin(bin, max_len, b64, strlen(b64), NULL, out_len, NULL,
                          sodium_base64_VARIANT_ORIGINAL) != 0) {
        free(bin);
        return NULL;
    }
    return bin;
}

// Encrypt bytes with XChaCha20-Poly1305; returns base64 encoded (nonce+cipher)
char* encrypt_bytes(const uint8_t* data, size_t len,
                    const uint8_t* key, size_t key_len) {
    if (key_len != crypto_aead_xchacha20poly1305_ietf_KEYBYTES) {
        return NULL;
    }

    if (sodium_init() < 0) return NULL;

    // Allocate buffers
    unsigned char nonce[crypto_aead_xchacha20poly1305_ietf_NPUBBYTES];
    randombytes_buf(nonce, sizeof nonce);

    unsigned long long cipher_len = len + crypto_aead_xchacha20poly1305_ietf_ABYTES;
    unsigned char* cipher = malloc(cipher_len);
    if (cipher == NULL) return NULL;

    if (crypto_aead_xchacha20poly1305_ietf_encrypt(
            cipher, &cipher_len,
            data, len,
            NULL, 0, // no additional data
            NULL,
            nonce, key) != 0) {
        free(cipher);
        return NULL;
    }

    size_t total_len = sizeof nonce + cipher_len;
    unsigned char* combined = malloc(total_len);
    if (combined == NULL) {
        free(cipher);
        return NULL;
    }
    memcpy(combined, nonce, sizeof nonce);
    memcpy(combined + sizeof nonce, cipher, cipher_len);

    free(cipher);

    char* b64 = _bin_to_b64(combined, total_len);
    sodium_memzero((void*)key, key_len);
    sodium_memzero(combined, total_len);
    free(combined);

    return b64; // may be NULL if encoding failed
}

// Decrypt base64 blob back to plaintext; returns base64 of plaintext
char* decrypt_bytes(const char* enc_b64,
                    const uint8_t* key, size_t key_len) {
    if (key_len != crypto_aead_xchacha20poly1305_ietf_KEYBYTES) {
        return NULL;
    }

    if (sodium_init() < 0) return NULL;

    size_t enc_len;
    unsigned char* enc_bin = _b64_to_bin(enc_b64, &enc_len);
    if (enc_bin == NULL) return NULL;

    if (enc_len < crypto_aead_xchacha20poly1305_ietf_NPUBBYTES +
                 crypto_aead_xchacha20poly1305_ietf_ABYTES) {
        free(enc_bin);
        return NULL;
    }

    unsigned char nonce[crypto_aead_xchacha20poly1305_ietf_NPUBBYTES];
    memcpy(nonce, enc_bin, sizeof nonce);

    unsigned char* cipher = enc_bin + sizeof nonce;
    unsigned long long cipher_len = enc_len - sizeof nonce;

    unsigned char* plain = malloc(cipher_len); // decrypt len <= cipher_len
    if (plain == NULL) {
        free(enc_bin);
        return NULL;
    }

    unsigned long long plain_len;
    if (crypto_aead_xchacha20poly1305_ietf_decrypt(
            plain, &plain_len,
            NULL,
            cipher, cipher_len,
            NULL, 0,
            nonce, key) != 0) {
        // decryption failed
        sodium_memzero(plain, cipher_len);
        free(plain);
        free(enc_bin);
        return NULL;
    }

    char* b64_plain = _bin_to_b64(plain, plain_len);

    sodium_memzero((void*)key, key_len);
    sodium_memzero(plain, plain_len);
    free(plain);
    free(enc_bin);

    return b64_plain; // may be NULL if encoding failed
} 