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

#endif // NATIVE_CRYPTO_H 