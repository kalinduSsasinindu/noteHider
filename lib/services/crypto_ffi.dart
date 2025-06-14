import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

// Define a C function signature for our native function.
// It takes no arguments and returns a pointer to a UTF8 string.
typedef _GetLibsodiumVersionStringC = Pointer<Utf8> Function();

// Define the Dart function signature. It's the same for this simple case.
typedef _GetLibsodiumVersionStringDart = Pointer<Utf8> Function();

// Signature for the password hashing function.
// Takes a pointer to a UTF8 string (the password) and returns a pointer to a UTF8 string (the hash).
typedef _HashPasswordC = Pointer<Utf8> Function(Pointer<Utf8> password);
typedef _HashPasswordDart = Pointer<Utf8> Function(Pointer<Utf8> password);

// Signature for the password verification function.
typedef _VerifyPasswordC = Bool Function(
    Pointer<Utf8> hash, Pointer<Utf8> password);
typedef _VerifyPasswordDart = bool Function(
    Pointer<Utf8> hash, Pointer<Utf8> password);

// Signature for the function to free memory.
// Takes a pointer to a UTF8 string and returns void.
typedef _FreeStringC = Void Function(Pointer<Utf8> str);
typedef _FreeStringDart = void Function(Pointer<Utf8> str);

/// A class to encapsulate the FFI calls to our native crypto library.
class CryptoFFI {
  // Singleton pattern to ensure the library is loaded only once.
  static final CryptoFFI _instance = CryptoFFI._internal();
  factory CryptoFFI() => _instance;

  late final DynamicLibrary _dylib;
  late final _GetLibsodiumVersionStringDart _getLibsodiumVersionString;
  late final _HashPasswordDart _hashPassword;
  late final _VerifyPasswordDart _verifyPassword;
  late final _FreeStringDart _freeString;

  CryptoFFI._internal() {
    _dylib = _loadDylib();
    _initializeFunctions();
    print("Native crypto library loaded.");
  }

  /// Looks up the C functions from the dynamic library and makes them
  /// available as callable Dart functions.
  void _initializeFunctions() {
    _getLibsodiumVersionString = _dylib
        .lookup<NativeFunction<_GetLibsodiumVersionStringC>>(
            'get_libsodium_version_string')
        .asFunction<_GetLibsodiumVersionStringDart>();

    _hashPassword = _dylib
        .lookup<NativeFunction<_HashPasswordC>>('hash_password')
        .asFunction<_HashPasswordDart>();

    _verifyPassword = _dylib
        .lookup<NativeFunction<_VerifyPasswordC>>('verify_password')
        .asFunction<_VerifyPasswordDart>();

    _freeString = _dylib
        .lookup<NativeFunction<_FreeStringC>>('free_string')
        .asFunction<_FreeStringDart>();
  }

  /// Loads the dynamic library from the correct path based on the platform.
  DynamicLibrary _loadDylib() {
    const libName = 'native_crypto_library';
    if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open('lib$libName.so');
    }
    if (Platform.isIOS) {
      // iOS apps are statically linked, so we can open the process itself.
      return DynamicLibrary.executable();
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open('$libName.dll');
    }
    if (Platform.isMacOS) {
      return DynamicLibrary.open('lib$libName.dylib');
    }
    throw UnsupportedError('Unsupported platform for FFI');
  }

  /// Calls the native function and converts the result to a Dart String.
  String getLibsodiumVersion() {
    final versionPointer = _getLibsodiumVersionString();
    // Convert the C string (Pointer<Utf8>) to a Dart String.
    final version = versionPointer.toDartString();
    return version;
  }

  /// Hashes a password using the native libsodium implementation.
  String hashPassword(String password) {
    // Convert the Dart String to a C-compatible Utf8 pointer.
    final passwordPointer = password.toNativeUtf8();

    // Call the native function.
    final hashPointer = _hashPassword(passwordPointer);

    // Convert the resulting C string back to a Dart String.
    final hash = hashPointer.toDartString();

    // IMPORTANT: Free the memory that was allocated by the C functions.
    // We must free both the password pointer and the hash pointer.
    _freeString(hashPointer);
    calloc.free(passwordPointer);

    return hash;
  }

  /// Verifies a password against a native hash.
  bool verifyPassword(String hash, String password) {
    // Convert Dart Strings to C-compatible Utf8 pointers.
    final hashPointer = hash.toNativeUtf8();
    final passwordPointer = password.toNativeUtf8();

    // Call the native function.
    final isValid = _verifyPassword(hashPointer, passwordPointer);

    // IMPORTANT: Free the allocated memory.
    calloc.free(hashPointer);
    calloc.free(passwordPointer);

    return isValid;
  }
}
