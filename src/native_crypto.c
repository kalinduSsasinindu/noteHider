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