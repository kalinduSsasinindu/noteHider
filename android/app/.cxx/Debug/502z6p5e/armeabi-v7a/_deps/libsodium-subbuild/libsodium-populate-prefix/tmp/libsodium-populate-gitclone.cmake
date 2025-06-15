
if(NOT "C:/Users/kalin/Desktop/flutter sources/notehider/android/app/.cxx/Debug/502z6p5e/armeabi-v7a/_deps/libsodium-subbuild/libsodium-populate-prefix/src/libsodium-populate-stamp/libsodium-populate-gitinfo.txt" IS_NEWER_THAN "C:/Users/kalin/Desktop/flutter sources/notehider/android/app/.cxx/Debug/502z6p5e/armeabi-v7a/_deps/libsodium-subbuild/libsodium-populate-prefix/src/libsodium-populate-stamp/libsodium-populate-gitclone-lastrun.txt")
  message(STATUS "Avoiding repeated git clone, stamp file is up to date: 'C:/Users/kalin/Desktop/flutter sources/notehider/android/app/.cxx/Debug/502z6p5e/armeabi-v7a/_deps/libsodium-subbuild/libsodium-populate-prefix/src/libsodium-populate-stamp/libsodium-populate-gitclone-lastrun.txt'")
  return()
endif()

execute_process(
  COMMAND ${CMAKE_COMMAND} -E rm -rf "C:/Users/kalin/Desktop/flutter sources/notehider/android/app/.cxx/Debug/502z6p5e/armeabi-v7a/_deps/libsodium-src"
  RESULT_VARIABLE error_code
  )
if(error_code)
  message(FATAL_ERROR "Failed to remove directory: 'C:/Users/kalin/Desktop/flutter sources/notehider/android/app/.cxx/Debug/502z6p5e/armeabi-v7a/_deps/libsodium-src'")
endif()

# try the clone 3 times in case there is an odd git clone issue
set(error_code 1)
set(number_of_tries 0)
while(error_code AND number_of_tries LESS 3)
  execute_process(
    COMMAND "C:/Users/kalin/AppData/Local/Programs/Git/cmd/git.exe"  clone --no-checkout --config "advice.detachedHead=false" "https://github.com/robinlinden/libsodium-cmake.git" "libsodium-src"
    WORKING_DIRECTORY "C:/Users/kalin/Desktop/flutter sources/notehider/android/app/.cxx/Debug/502z6p5e/armeabi-v7a/_deps"
    RESULT_VARIABLE error_code
    )
  math(EXPR number_of_tries "${number_of_tries} + 1")
endwhile()
if(number_of_tries GREATER 1)
  message(STATUS "Had to git clone more than once:
          ${number_of_tries} times.")
endif()
if(error_code)
  message(FATAL_ERROR "Failed to clone repository: 'https://github.com/robinlinden/libsodium-cmake.git'")
endif()

execute_process(
  COMMAND "C:/Users/kalin/AppData/Local/Programs/Git/cmd/git.exe"  checkout e5b985ad0dd235d8c4307ea3a385b45e76c74c6a --
  WORKING_DIRECTORY "C:/Users/kalin/Desktop/flutter sources/notehider/android/app/.cxx/Debug/502z6p5e/armeabi-v7a/_deps/libsodium-src"
  RESULT_VARIABLE error_code
  )
if(error_code)
  message(FATAL_ERROR "Failed to checkout tag: 'e5b985ad0dd235d8c4307ea3a385b45e76c74c6a'")
endif()

set(init_submodules TRUE)
if(init_submodules)
  execute_process(
    COMMAND "C:/Users/kalin/AppData/Local/Programs/Git/cmd/git.exe"  submodule update --recursive --init 
    WORKING_DIRECTORY "C:/Users/kalin/Desktop/flutter sources/notehider/android/app/.cxx/Debug/502z6p5e/armeabi-v7a/_deps/libsodium-src"
    RESULT_VARIABLE error_code
    )
endif()
if(error_code)
  message(FATAL_ERROR "Failed to update submodules in: 'C:/Users/kalin/Desktop/flutter sources/notehider/android/app/.cxx/Debug/502z6p5e/armeabi-v7a/_deps/libsodium-src'")
endif()

# Complete success, update the script-last-run stamp file:
#
execute_process(
  COMMAND ${CMAKE_COMMAND} -E copy
    "C:/Users/kalin/Desktop/flutter sources/notehider/android/app/.cxx/Debug/502z6p5e/armeabi-v7a/_deps/libsodium-subbuild/libsodium-populate-prefix/src/libsodium-populate-stamp/libsodium-populate-gitinfo.txt"
    "C:/Users/kalin/Desktop/flutter sources/notehider/android/app/.cxx/Debug/502z6p5e/armeabi-v7a/_deps/libsodium-subbuild/libsodium-populate-prefix/src/libsodium-populate-stamp/libsodium-populate-gitclone-lastrun.txt"
  RESULT_VARIABLE error_code
  )
if(error_code)
  message(FATAL_ERROR "Failed to copy script-last-run stamp file: 'C:/Users/kalin/Desktop/flutter sources/notehider/android/app/.cxx/Debug/502z6p5e/armeabi-v7a/_deps/libsodium-subbuild/libsodium-populate-prefix/src/libsodium-populate-stamp/libsodium-populate-gitclone-lastrun.txt'")
endif()

