import 'dart:ffi';
import 'dart:io';
import 'dart:convert';

import 'package:ffi/ffi.dart';
import 'package:crypto/crypto.dart';

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
    String path;

    if (Platform.isAndroid || Platform.isLinux) {
      path = 'lib$libName.so';
    } else if (Platform.isIOS) {
      // iOS apps are statically linked, so we can open the process itself.
      return DynamicLibrary.executable();
    } else if (Platform.isWindows) {
      path = '$libName.dll';
    } else if (Platform.isMacOS) {
      path = 'lib$libName.dylib';
    } else {
      throw UnsupportedError('Unsupported platform for FFI');
    }

    // 🔒 Verify integrity of the native binary before loading it.
    _verifyDylibChecksum(path);

    return DynamicLibrary.open(path);
  }

  /// Computes SHA-256 of the dynamic library on disk. On first run we write a
  /// side-car file `<lib>.sha256`. Subsequent launches compare against the
  /// stored value and abort if it differs (indicating possible tampering).
  void _verifyDylibChecksum(String dylibPath) {
    // Skip on iOS – we are statically linked within the executable.
    if (Platform.isIOS) return;

    final file = File(dylibPath);
    if (!file.existsSync()) {
      throw StateError('Native library not found at $dylibPath');
    }

    final bytes = file.readAsBytesSync();
    final currentHash = sha256.convert(bytes).toString();

    final checksumFile = File('$dylibPath.sha256');
    if (!checksumFile.existsSync()) {
      // First launch: persist checksum lock-file next to the library.
      checksumFile.writeAsStringSync(currentHash, flush: true);
      return;
    }

    final storedHash = checksumFile.readAsStringSync();
    if (storedHash != currentHash) {
      throw StateError(
          'Native library checksum mismatch – expected $storedHash, got $currentHash. Possible tampering detected.');
    }
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

    // 🔐 Wipe password buffer before releasing it to the allocator to reduce
    // the lifetime of secret material in memory.
    final pwdLen = utf8.encode(password).length + 1; // +1 for null-terminator
    final pwdView = passwordPointer.cast<Uint8>().asTypedList(pwdLen);
    for (int i = 0; i < pwdView.length; i++) {
      pwdView[i] = 0;
    }
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
    // Wipe both buffers before freeing.
    final hashLen = utf8.encode(hash).length + 1;
    final hashView = hashPointer.cast<Uint8>().asTypedList(hashLen);
    for (int i = 0; i < hashView.length; i++) {
      hashView[i] = 0;
    }

    final pwdLen = utf8.encode(password).length + 1;
    final pwdView = passwordPointer.cast<Uint8>().asTypedList(pwdLen);
    for (int i = 0; i < pwdView.length; i++) {
      pwdView[i] = 0;
    }

    calloc.free(hashPointer);
    calloc.free(passwordPointer);

    return isValid;
  }
}
