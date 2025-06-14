cmake_minimum_required(VERSION 3.14)

# Project Name
project(native_crypto)

# Use FetchContent to download and build libsodium
include(FetchContent)
FetchContent_Declare(
    libsodium
    GIT_REPOSITORY https://github.com/robinlinden/libsodium-cmake.git
    GIT_TAG e5b985ad0dd235d8c4307ea3a385b45e76c74c6a # stable tag
)
FetchContent_MakeAvailable(libsodium)

# Define our own library, which will contain our wrapper functions.
add_library(
        native_crypto_library
        SHARED
        native_crypto.c
        native_integrity.c
)

# Link our library against libsodium. This makes the libsodium functions
# available to our code.
target_link_libraries(
        native_crypto_library
        # The name 'sodium' is defined within libsodium's own CMakeLists.txt
        sodium
)

# On Apple platforms, libsodium needs this framework.
if(APPLE)
    target_link_libraries(native_crypto_library "-framework Security")
endif()

# On Android, link with the log library.
if(ANDROID)
    target_link_libraries(
            native_crypto_library
            # The 'log' library is used for android_util_log_print, etc.
            log
    )
endif()