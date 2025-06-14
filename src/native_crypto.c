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

const char* hash_password(const char* password) {
    char hashed_password[crypto_pwhash_STRBYTES];

    // Use the default recommended limits for opslimit and memlimit.
    if (crypto_pwhash_str(hashed_password, password, strlen(password),
                          crypto_pwhash_OPSLIMIT_INTERACTIVE,
                          crypto_pwhash_MEMLIMIT_INTERACTIVE) != 0) {
        return "{\"error\": \"Failed to hash password\"}";
    }

    // Allocate memory on the heap for the result and copy the hash.
    char* result = (char*)malloc(strlen(hashed_password) + 1);
    if (result == NULL) {
        return "{\"error\": \"Memory allocation failed\"}";
    }
    strcpy(result, hashed_password);

    return result;
}

bool verify_password(const char* hash, const char* password) {
    if (crypto_pwhash_str_verify(hash, password, strlen(password)) != 0) {
        // Wrong password
        return false;
    }
    // Correct password
    return true;
}

void free_string(char* str) {
    if (str != NULL) {
        free(str);
    }
} 