#ifndef NATIVE_CRYPTO_H
#define NATIVE_CRYPTO_H

// This is a standard C header guard to prevent the file from being included multiple times.

// We include these standard headers to get definitions for types like int32_t, etc.,
// which helps ensure our C types match our Dart types.
#include <stdint.h>
#include <stdbool.h>

// A test function to get the libsodium version string. We'll use this
// to verify that our FFI bridge is working correctly.
const char* get_libsodium_version_string();

// Hashes a password using libsodium's Argon2id implementation.
// Returns a JSON string with the hash result, or an error message.
// The caller is responsible for freeing the returned string using free_string().
const char* hash_password(const char* password);

// Verifies a password against a libsodium hash string.
// Returns true if the password is valid, false otherwise.
bool verify_password(const char* hash, const char* password);

// Frees a string that was allocated in C.
void free_string(char* str);

// Encrypts arbitrary bytes with libsodium (XChaCha20-Poly1305). Returns a
// base-64 string (nonce + ciphertext + MAC) allocated via malloc. Caller must
// free the returned pointer using free_string(). Returns NULL on failure.
char* encrypt_bytes(const uint8_t* data, size_t len,
                    const uint8_t* key, size_t key_len);

// Decrypts a base-64 string produced by encrypt_bytes(). On success returns a
// base-64 string containing the plaintext bytes. Caller must free the pointer
// with free_string(). Returns NULL on failure (e.g. invalid MAC).
char* decrypt_bytes(const char* enc_b64,
                    const uint8_t* key, size_t key_len);

#endif // NATIVE_CRYPTO_H 