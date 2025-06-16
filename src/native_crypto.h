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

// === Added FFI helpers for Dart ===

// Fills \[len] bytes of cryptographically-secure random data into [buf].
// Returns 0 on success, -1 on failure.
int random_bytes(uint8_t* buf, size_t len);

// Securely wipes [len] bytes at [ptr] using sodium_memzero(). Always returns 0.
int secure_memzero(void* ptr, size_t len);

// Generic HKDF-SHA256 extractor/expander as per RFC-5869.
// Derives [okm_len] bytes into [okm] from ikm + salt + info. Returns 0 on success.
int hkdf_sha256(const uint8_t* ikm, size_t ikm_len,
                const uint8_t* salt, size_t salt_len,
                const uint8_t* info, size_t info_len,
                uint8_t* okm, size_t okm_len);

// Convenience wrapper specialised for NoteHider –
// derives a 32-byte session key from master_key || ephemeral_key using [salt].
// Returns a malloc'ed base-64 string containing the 32-byte key; caller must
// free it via free_string(). Returns NULL on failure.
char* derive_session_key_b64(const uint8_t* master_key, size_t master_len,
                             const uint8_t* ephemeral_key, size_t eph_len,
                             const uint8_t* salt, size_t salt_len);

// Provides [len] random bytes encoded as base-64. Caller frees using free_string().
char* random_bytes_b64(size_t len);

// Derives a key using PBKDF2-HMAC-SHA256 (compat path). Returns base-64
// encoded derived key (dk_len bytes). Caller frees with free_string().
char* pbkdf2_sha256_b64(const char* password,
                        const uint8_t* salt, size_t salt_len,
                        size_t dk_len);

#endif // NATIVE_CRYPTO_H 