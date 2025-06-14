# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.22.1-g37088a8-dirty)

# We name the project and the target for the ExternalProject_Add() call
# to something that will highlight to the user what we are working on if
# something goes wrong and an error message is produced.

project(libsodium-populate NONE)


# Pass through things we've already detected in the main project to avoid
# paying the cost of redetecting them again in ExternalProject_Add()
set(GIT_EXECUTABLE [==[C:/Users/kalin/AppData/Local/Programs/Git/cmd/git.exe]==])
set(GIT_VERSION_STRING [==[2.44.0.windows.1]==])
set_property(GLOBAL PROPERTY _CMAKE_FindGit_GIT_EXECUTABLE_VERSION
  [==[C:/Users/kalin/AppData/Local/Programs/Git/cmd/git.exe;2.44.0.windows.1]==]
)


include(ExternalProject)
ExternalProject_Add(libsodium-populate
                     "UPDATE_DISCONNECTED" "False" "GIT_REPOSITORY" "https://github.com/robinlinden/libsodium-cmake.git" "GIT_TAG" "e5b985ad0dd235d8c4307ea3a385b45e76c74c6a"
                    SOURCE_DIR          "C:/Users/kalin/Desktop/flutter sources/notehider/android/app/.cxx/Debug/502z6p5e/arm64-v8a/_deps/libsodium-src"
                    BINARY_DIR          "C:/Users/kalin/Desktop/flutter sources/notehider/android/app/.cxx/Debug/502z6p5e/arm64-v8a/_deps/libsodium-build"
                    CONFIGURE_COMMAND   ""
                    BUILD_COMMAND       ""
                    INSTALL_COMMAND     ""
                    TEST_COMMAND        ""
                    USES_TERMINAL_DOWNLOAD  YES
                    USES_TERMINAL_UPDATE    YES
)


