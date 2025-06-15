import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

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

// Native symmetric encryption / decryption
typedef _EncryptBytesC = Pointer<Utf8> Function(
    Pointer<Uint8> data, IntPtr dataLen, Pointer<Uint8> key, IntPtr keyLen);
typedef _EncryptBytesDart = Pointer<Utf8> Function(
    Pointer<Uint8> data, int dataLen, Pointer<Uint8> key, int keyLen);

typedef _DecryptBytesC = Pointer<Utf8> Function(
    Pointer<Utf8> cipher, Pointer<Uint8> key, IntPtr keyLen);
typedef _DecryptBytesDart = Pointer<Utf8> Function(
    Pointer<Utf8> cipher, Pointer<Uint8> key, int keyLen);

// Native random bytes base64
typedef _RandomBytesB64C = Pointer<Utf8> Function(IntPtr len);
typedef _RandomBytesB64Dart = Pointer<Utf8> Function(int len);

// Native HKDF session key derivation – returns base64 key
typedef _DeriveSessionKeyB64C = Pointer<Utf8> Function(
    Pointer<Uint8> master,
    IntPtr masterLen,
    Pointer<Uint8> eph,
    IntPtr ephLen,
    Pointer<Uint8> salt,
    IntPtr saltLen);
typedef _DeriveSessionKeyB64Dart = Pointer<Utf8> Function(
    Pointer<Uint8> master,
    int masterLen,
    Pointer<Uint8> eph,
    int ephLen,
    Pointer<Uint8> salt,
    int saltLen);

// Native PBKDF2
typedef _Pbkdf2B64C = Pointer<Utf8> Function(
    Pointer<Utf8> pwd, Pointer<Uint8> salt, IntPtr saltLen, IntPtr dkLen);
typedef _Pbkdf2B64Dart = Pointer<Utf8> Function(
    Pointer<Utf8> pwd, Pointer<Uint8> salt, int saltLen, int dkLen);

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
  late final _EncryptBytesDart _encryptBytes;
  late final _DecryptBytesDart _decryptBytes;
  late final _RandomBytesB64Dart _randomBytesB64;
  late final _DeriveSessionKeyB64Dart _deriveSessionKeyB64;
  late final _Pbkdf2B64Dart _pbkdf2B64;

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

    // Native symmetric encryption / decryption
    _encryptBytes = _dylib
        .lookup<NativeFunction<_EncryptBytesC>>('encrypt_bytes')
        .asFunction<_EncryptBytesDart>();

    _decryptBytes = _dylib
        .lookup<NativeFunction<_DecryptBytesC>>('decrypt_bytes')
        .asFunction<_DecryptBytesDart>();

    // --- New helpers ---
    _randomBytesB64 = _dylib
        .lookup<NativeFunction<_RandomBytesB64C>>('random_bytes_b64')
        .asFunction<_RandomBytesB64Dart>();

    _deriveSessionKeyB64 = _dylib
        .lookup<NativeFunction<_DeriveSessionKeyB64C>>('derive_session_key_b64')
        .asFunction<_DeriveSessionKeyB64Dart>();

    _pbkdf2B64 = _dylib
        .lookup<NativeFunction<_Pbkdf2B64C>>('pbkdf2_sha256_b64')
        .asFunction<_Pbkdf2B64Dart>();
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
    // On mobile platforms the library lives inside the app sandbox at a
    // runtime-determined path that File() can't access via a simple relative
    // name. We keep the checksum lock for desktop platforms where the path is
    // predictable. Mobile integrity is instead covered by Play Integrity /
    // App Attest.
    if (Platform.isIOS || Platform.isAndroid) return;

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

  /// Encrypts arbitrary bytes with a given key using libsodium (native).
  /// Returns the encrypted bytes (nonce + ciphertext + MAC) as raw bytes.
  Uint8List encryptBytes(Uint8List data, Uint8List key) {
    final dataPtr = calloc<Uint8>(data.length);
    final keyPtr = calloc<Uint8>(key.length);

    dataPtr.asTypedList(data.length).setAll(0, data);
    keyPtr.asTypedList(key.length).setAll(0, key);

    final encPtr = _encryptBytes(dataPtr, data.length, keyPtr, key.length);

    // Clean sensitive buffers before freeing.
    for (var i = 0; i < key.length; i++) {
      keyPtr[i] = 0;
    }
    calloc.free(dataPtr);
    calloc.free(keyPtr);

    if (encPtr.address == 0) {
      throw StateError('Native encryption failed');
    }

    final encBase64 = encPtr.toDartString();
    _freeString(encPtr);

    return base64.decode(encBase64);
  }

  /// Decrypts bytes that were encrypted with [encryptBytes].
  Uint8List decryptBytes(Uint8List encryptedBytes, Uint8List key) {
    final cipherB64 = base64.encode(encryptedBytes);

    final cipherPtr = cipherB64.toNativeUtf8();
    final keyPtr = calloc<Uint8>(key.length);
    keyPtr.asTypedList(key.length).setAll(0, key);

    final plainPtr = _decryptBytes(cipherPtr, keyPtr, key.length);

    // Wipe key buffer
    for (var i = 0; i < key.length; i++) {
      keyPtr[i] = 0;
    }
    calloc.free(keyPtr);

    // wipe cipher buffer
    final cipherView =
        cipherPtr.cast<Uint8>().asTypedList(cipherB64.length + 1);
    for (var i = 0; i < cipherView.length; i++) {
      cipherView[i] = 0;
    }
    calloc.free(cipherPtr);

    if (plainPtr.address == 0) {
      throw StateError('Native decryption failed');
    }

    final plainBase64 = plainPtr.toDartString();
    _freeString(plainPtr);

    return base64.decode(plainBase64);
  }

  Uint8List randomBytes(int len) {
    final ptr = _randomBytesB64(len);
    if (ptr.address == 0) {
      throw StateError('random_bytes_b64 failed');
    }
    final b64 = ptr.toDartString();
    _freeString(ptr);
    return base64.decode(b64);
  }

  Uint8List deriveSessionKey(Uint8List master, Uint8List eph, Uint8List salt) {
    final masterPtr = calloc<Uint8>(master.length);
    final ephPtr = calloc<Uint8>(eph.length);
    final saltPtr = calloc<Uint8>(salt.length);

    masterPtr.asTypedList(master.length).setAll(0, master);
    ephPtr.asTypedList(eph.length).setAll(0, eph);
    saltPtr.asTypedList(salt.length).setAll(0, salt);

    final ptr = _deriveSessionKeyB64(
        masterPtr, master.length, ephPtr, eph.length, saltPtr, salt.length);

    // Wipe and free input buffers
    for (int i = 0; i < master.length; i++) {
      masterPtr[i] = 0;
    }
    for (int i = 0; i < eph.length; i++) {
      ephPtr[i] = 0;
    }
    for (int i = 0; i < salt.length; i++) {
      saltPtr[i] = 0;
    }
    calloc.free(masterPtr);
    calloc.free(ephPtr);
    calloc.free(saltPtr);

    if (ptr.address == 0) {
      throw StateError('derive_session_key_b64 failed');
    }
    final b64 = ptr.toDartString();
    _freeString(ptr);
    return base64.decode(b64);
  }

  Uint8List pbkdf2Sha256(String password, Uint8List salt, int dkLen) {
    final pwdPtr = password.toNativeUtf8();
    final saltPtr = calloc<Uint8>(salt.length);
    saltPtr.asTypedList(salt.length).setAll(0, salt);

    final ptr = _pbkdf2B64(pwdPtr, saltPtr, salt.length, dkLen);

    // wipe
    final pwdBytes = pwdPtr.cast<Uint8>().asTypedList(password.length + 1);
    for (int i = 0; i < pwdBytes.length; i++) {
      pwdBytes[i] = 0;
    }
    calloc.free(pwdPtr);
    for (int i = 0; i < salt.length; i++) {
      saltPtr[i] = 0;
    }
    calloc.free(saltPtr);

    if (ptr.address == 0) {
      throw StateError('pbkdf2_sha256_b64 failed');
    }
    final b64 = ptr.toDartString();
    _freeString(ptr);
    return base64.decode(b64);
  }
}
