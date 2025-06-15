#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "native_crypto.h" // Our own header file.
#include "sodium.h" // The main header from the libsodium library.

#if defined(__ANDROID__) || defined(__APPLE__)
#define NH_OPSLIMIT crypto_pwhash_OPSLIMIT_MODERATE
#define NH_MEMLIMIT crypto_pwhash_MEMLIMIT_MODERATE
#else
#define NH_OPSLIMIT crypto_pwhash_OPSLIMIT_SENSITIVE
#define NH_MEMLIMIT crypto_pwhash_MEMLIMIT_SENSITIVE
#endif

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

// Hash password and return malloc'ed hash string (Argon2id). Caller must free
// using free_string(). Returns NULL on failure.
const char* hash_password(const char* password) {
    if (sodium_init() < 0) return NULL;

    char* out = malloc(crypto_pwhash_STRBYTES);
    if (!out) return NULL;

    if (crypto_pwhash_str(out,
                          password,
                          strlen(password),
                          NH_OPSLIMIT,
                          NH_MEMLIMIT) != 0) {
        free(out);
        return NULL;
    }
    return out;
}

bool verify_password(const char* hash, const char* password) {
    if (sodium_init() < 0) return false;
    return crypto_pwhash_str_verify(hash, password, strlen(password)) == 0;
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

// === Added FFI helper implementations ===

int random_bytes(uint8_t* buf, size_t len) {
    if (sodium_init() < 0) return -1;
    if (buf == NULL || len == 0) return -1;
    randombytes_buf(buf, len);
    return 0;
}

int secure_memzero(void* ptr, size_t len) {
    if (ptr == NULL || len == 0) return 0;
    sodium_memzero(ptr, len);
    return 0;
}

int hkdf_sha256(const uint8_t* ikm, size_t ikm_len,
                const uint8_t* salt, size_t salt_len,
                const uint8_t* info, size_t info_len,
                uint8_t* okm, size_t okm_len) {
    if (sodium_init() < 0) return -1;
    if (okm_len == 0 || okm == NULL) return -1;

    const size_t hash_len = crypto_auth_hmacsha256_BYTES; // 32 bytes
    const size_t n = (okm_len + hash_len - 1) / hash_len;
    if (n > 255) return -1; // RFC 5869 limit

    unsigned char _salt[crypto_auth_hmacsha256_KEYBYTES] = {0};
    if (salt == NULL || salt_len == 0) {
        salt = _salt;
        salt_len = sizeof(_salt);
    }

    unsigned char prk[crypto_auth_hmacsha256_BYTES];
    crypto_auth_hmacsha256_state state;
    crypto_auth_hmacsha256_init(&state, salt, salt_len);
    crypto_auth_hmacsha256_update(&state, ikm, ikm_len);
    crypto_auth_hmacsha256_final(&state, prk);

    unsigned char t[crypto_auth_hmacsha256_BYTES];
    size_t t_len = 0;
    size_t written = 0;

    for (size_t i = 1; i <= n; i++) {
        crypto_auth_hmacsha256_state st;
        crypto_auth_hmacsha256_init(&st, prk, hash_len);
        if (t_len > 0) {
            crypto_auth_hmacsha256_update(&st, t, t_len);
        }
        if (info && info_len > 0) {
            crypto_auth_hmacsha256_update(&st, info, info_len);
        }
        unsigned char c = (unsigned char)i;
        crypto_auth_hmacsha256_update(&st, &c, 1);
        crypto_auth_hmacsha256_final(&st, t);
        size_t copy_len = (written + hash_len > okm_len) ? (okm_len - written) : hash_len;
        memcpy(okm + written, t, copy_len);
        written += copy_len;
        t_len = hash_len;
    }

    // Zero sensitive data
    sodium_memzero(prk, sizeof prk);
    sodium_memzero(t, sizeof t);

    return 0;
}

char* derive_session_key_b64(const uint8_t* master_key, size_t master_len,
                             const uint8_t* ephemeral_key, size_t eph_len,
                             const uint8_t* salt, size_t salt_len) {
    if (master_key == NULL || master_len == 0 || eph_len == 0) return NULL;

    unsigned char ikm[64];
    size_t ikm_len = 0;
    if (master_len + eph_len > sizeof(ikm)) {
        // Fallback: allocate
        unsigned char* dyn = malloc(master_len + eph_len);
        if (!dyn) return NULL;
        memcpy(dyn, master_key, master_len);
        memcpy(dyn + master_len, ephemeral_key, eph_len);
        ikm_len = master_len + eph_len;
        // Derive key
        unsigned char out[32];
        if (hkdf_sha256(dyn, ikm_len, salt, salt_len, NULL, 0, out, sizeof(out)) != 0) {
            free(dyn);
            return NULL;
        }
        free(dyn);
        char* b64 = _bin_to_b64(out, sizeof(out));
        sodium_memzero(out, sizeof out);
        return b64;
    } else {
        memcpy(ikm, master_key, master_len);
        memcpy(ikm + master_len, ephemeral_key, eph_len);
        ikm_len = master_len + eph_len;
        unsigned char out[32];
        if (hkdf_sha256(ikm, ikm_len, salt, salt_len, NULL, 0, out, sizeof(out)) != 0) {
            return NULL;
        }
        char* b64 = _bin_to_b64(out, sizeof(out));
        sodium_memzero(out, sizeof out);
        sodium_memzero(ikm, sizeof ikm);
        return b64;
    }
}

char* random_bytes_b64(size_t len) {
    if (sodium_init() < 0) return NULL;
    unsigned char* buf = malloc(len);
    if (!buf) return NULL;
    randombytes_buf(buf, len);
    char* b64 = _bin_to_b64(buf, len);
    sodium_memzero(buf, len);
    free(buf);
    return b64;
}

// PBKDF2-HMAC-SHA256 key derivation (compatibility with legacy master key)
char* pbkdf2_sha256_b64(const char* password,
                        const uint8_t* salt, size_t salt_len,
                        uint32_t iterations,
                        size_t dk_len) {
    if (password == NULL || salt == NULL || dk_len == 0) return NULL;
    if (sodium_init() < 0) return NULL;

    unsigned char* dk = malloc(dk_len);
    if (!dk) return NULL;

    if (crypto_pwhash(dk, dk_len,
                       password, strlen(password),
                       salt, iterations,
                       crypto_pwhash_MEMLIMIT_INTERACTIVE,
                       crypto_pwhash_alg_default()) != 0) {
        free(dk);
        return NULL;
    }

    char* b64 = _bin_to_b64(dk, dk_len);
    sodium_memzero(dk, dk_len);
    free(dk);
    return b64;
} 