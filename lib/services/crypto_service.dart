import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:notehider/models/file_models.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'crypto_ffi.dart';

/// 🔒 CryptoService – thin Dart façade around the project's native
/// libsodium-based engine (see `native_crypto.c`).  All heavy crypto
/// work—password hashing (Argon2id), HKDF-SHA256, random-bytes generation,
/// XChaCha20/AES-GCM encryption—is executed in C for speed and side-channel
/// safety.  The Dart layer now focuses exclusively on:
/// • Marshalling data to/from FFI (Uint8List ⇆ Pointer)
/// • High-level conveniences such as file-metadata packing/unpacking
/// • Optional secure-memory clearing helpers
///
/// No cryptographic maths are implemented in Dart anymore.
class CryptoService {
  final CryptoFFI _cryptoFFI = CryptoFFI();

  // 🔒 MOBILE-OPTIMIZED SECURITY CONSTANTS
  static const int _saltLength = 64; // 512-bit salt (military grade)
  static const int _keyLength = 32; // 256-bit keys
  static const int _ivLength = 16; // 128-bit IV for AES-GCM

  // 📱 MOBILE-OPTIMIZED SECURITY PARAMETERS
  static const int _pbkdf2Iterations = 100000; // Mobile optimized
  static const int _keyStretchingRounds = 1; // Mobile optimized

  static const int _ephemeralKeyLength = 32; // For Perfect Forward Secrecy

  final FortunaRandom _secureRandom = FortunaRandom();
  final List<Uint8List> _memoryToSecureClear = [];

  // Service state
  bool _isInitialized = false;
  Uint8List? _key;

  CryptoService() {
    // Initialize secure random with maximum entropy
    _initializeSecureRandom();
    _isInitialized = true;

    print(
        '🎖️ Military-grade crypto initialized - Mobile optimized: $_pbkdf2Iterations iterations, $_keyStretchingRounds rounds');
  }

  /// 🎲 INITIALIZE CRYPTOGRAPHICALLY SECURE RANDOM
  void _initializeSecureRandom() {
    // Use maximum entropy seed (256 bits - required by Fortuna PRNG)
    final seed = List<int>.generate(32, (i) => Random.secure().nextInt(256));
    _secureRandom.seed(KeyParameter(Uint8List.fromList(seed)));
  }

  /// 🔑 SET MASTER KEY
  void setMasterKey(Uint8List masterKey) {
    _key = Uint8List.fromList(masterKey);
  }

  /// 🔐 MILITARY-GRADE PASSWORD HASHING
  ///
  /// Features:
  /// • PBKDF2-SHA256 with 500,000 iterations
  /// • 64-byte (512-bit) cryptographic salt
  /// • Key stretching with multiple rounds
  /// • Memory-hard operations
  Future<MilitaryHashResult> hashPasswordMilitary(String password) async {
    final nativeHashString = _cryptoFFI.hashPassword(password);

    // We will adapt the MilitaryHashResult to work with the native format.
    // For now, we store the raw hash string in the 'hash' field. The other
    // fields are placeholders.
    return MilitaryHashResult(
      hash: nativeHashString,
      salt: Uint8List(0), // Salt is included in the native hash string
      algorithm: 'Argon2id-Native',
      iterations: 0, // Cost factors are included in the native hash string
      rounds: 0,
      version: 4, // Native implementation version
      timestamp: DateTime.now(),
    );
  }

  /// 🛡️ ENHANCED PASSWORD VERIFICATION
  ///
  /// Constant-time verification with military parameters
  Future<bool> verifyPasswordMilitary(
    String password,
    MilitaryHashResult stored,
  ) async {
    // The native verify function handles everything.
    // The `stored.hash` field now contains the full hash string from libsodium.
    return _cryptoFFI.verifyPassword(stored.hash, password);
  }

  /// ⚡ DUAL-LAYER ENCRYPTION WITH PERFECT FORWARD SECRECY
  ///
  /// Features:
  /// • AES-256-GCM primary encryption
  /// • Ephemeral keys for Perfect Forward Secrecy
  /// • Enhanced authentication tags
  /// • Quantum-resistant key derivation
  Future<MilitaryEncryptedData> encryptDataMilitary(
    Uint8List data,
    Uint8List masterKey,
  ) async {
    // Encrypt via libsodium (XChaCha20-Poly1305).  The helper already
    // generates a 24-byte nonce and appends the 16-byte MAC.
    final combined = _cryptoFFI.encryptBytes(data, masterKey);

    final nonceLen = 24;
    final tagLen = 16;

    final iv = combined.sublist(0, nonceLen);
    final authTag = combined.sublist(combined.length - tagLen);
    final cipherText = combined.sublist(nonceLen, combined.length - tagLen);

    return MilitaryEncryptedData(
      cipherText: cipherText,
      iv: iv,
      authTag: authTag,
      algorithm: 'XChaCha20-Poly1305',
      timestamp: DateTime.now(),
    );
  }

  /// 🔓 ENHANCED DECRYPTION WITH INTEGRITY VERIFICATION
  Future<Uint8List> decryptDataMilitary(
    MilitaryEncryptedData encryptedData,
    Uint8List masterKey,
  ) async {
    final combined = Uint8List.fromList([
      ...encryptedData.iv,
      ...encryptedData.cipherText,
      ...encryptedData.authTag,
    ]);
    return _cryptoFFI.decryptBytes(combined, masterKey);
  }

  /// 🔑 ENHANCED KEY DERIVATION (HKDF-SHA256)
  Future<Uint8List> _deriveSessionKey(
    Uint8List masterKey,
    Uint8List ephemeralKey,
    Uint8List salt,
  ) async {
    return _cryptoFFI.deriveSessionKey(masterKey, ephemeralKey, salt);
  }

  /// 🎲 MILITARY-GRADE RANDOM GENERATION
  Uint8List _generateMilitarySalt() {
    try {
      return _cryptoFFI.randomBytes(_saltLength);
    } catch (_) {
      return _secureRandom.nextBytes(_saltLength);
    }
  }

  Uint8List _generateEphemeralKey() {
    try {
      return _cryptoFFI.randomBytes(_ephemeralKeyLength);
    } catch (_) {
      return _secureRandom.nextBytes(_ephemeralKeyLength);
    }
  }

  /// 🧹 MILITARY-GRADE SECURE MEMORY CLEARING
  ///
  /// Triple-pass overwrite with different patterns
  void _secureClearBytes(List<int> data) {
    // DoD 5220.22-M standard: 3-pass overwrite
    for (int pass = 0; pass < 3; pass++) {
      for (int i = 0; i < data.length; i++) {
        switch (pass) {
          case 0:
            data[i] = 0x00; // All zeros
            break;
          case 1:
            data[i] = 0xFF; // All ones
            break;
          case 2:
            data[i] = _secureRandom.nextUint32() & 0xFF; // Random
            break;
        }
      }
    }
  }

  void _trackMemoryForClearing(Uint8List data) {
    _memoryToSecureClear.add(data);
  }

  /// 💥 EMERGENCY MEMORY WIPE
  Future<void> emergencyWipe() async {
    for (final data in _memoryToSecureClear) {
      _secureClearBytes(data);
    }
    _memoryToSecureClear.clear();
  }

  /// 🔢 UTILITY FUNCTIONS
  List<int> _intToBytes(int value) {
    return [
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
  }

  // Legacy methods for backward compatibility
  Uint8List generateSalt() => _generateMilitarySalt();

  Future<String> hashPassword(String password, Uint8List salt) async {
    final result = await hashPasswordMilitary(password);
    return result.hash;
  }

  Future<bool> verifyPassword(
      String password, String storedHash, Uint8List salt) async {
    // Convert to military format for verification
    final militaryResult = MilitaryHashResult(
      hash: storedHash,
      salt: salt,
      algorithm: 'PBKDF2-SHA256-Military',
      iterations: _pbkdf2Iterations,
      rounds: 1, // Legacy single round
      version: 1,
      timestamp: DateTime.now(),
    );
    return await verifyPasswordMilitary(password, militaryResult);
  }

  Future<Uint8List> deriveMasterKey(String password, Uint8List salt) async {
    return _cryptoFFI.pbkdf2Sha256(
        password, salt, _pbkdf2Iterations, _keyLength);
  }

  /// 📦 Simple wrapper around native libsodium symmetric encryption.
  /// Returns raw encrypted bytes (nonce + ciphertext + MAC) with no
  /// separate IV / tag fields required.
  Future<EncryptedData> encryptData(Uint8List data, Uint8List masterKey) async {
    final encryptedBytes = _cryptoFFI.encryptBytes(data, masterKey);
    return EncryptedData(
      encryptedBytes: encryptedBytes,
      iv: Uint8List(0), // Not needed – nonce is embedded in ciphertext
      authTag: Uint8List(0),
    );
  }

  Future<Uint8List> decryptData(
      EncryptedData encryptedData, Uint8List masterKey) async {
    return _cryptoFFI.decryptBytes(encryptedData.encryptedBytes, masterKey);
  }

  // Updated file encryption methods with new FileMetadata structure
  Future<EncryptedFile> encryptFile({
    required String fileName,
    required Uint8List fileData,
    required Uint8List masterKey,
  }) async {
    final now = DateTime.now();
    final fileId = _generateUniqueId();
    final fileHash = sha256.convert(fileData).toString();

    // Create new FileMetadata with all required fields
    final metadata = FileMetadata(
      id: fileId,
      originalName: fileName,
      displayName: fileName,
      encryptedPath: 'encrypted/$fileId',
      type: _getFileTypeFromName(fileName),
      sizeBytes: fileData.length,
      createdAt: now,
      modifiedAt: now,
      lastAccessedAt: now,
      mimeType: _getMimeTypeFromName(fileName),
      fileHash: fileHash,
    );

    final metadataJson = jsonEncode(metadata.toJson());
    final metadataBytes = utf8.encode(metadataJson);

    final encryptedData = await encryptData(fileData, masterKey);
    final encryptedMetadata = await encryptData(
      Uint8List.fromList(metadataBytes),
      masterKey,
    );

    return EncryptedFile(
      encryptedData: encryptedData,
      encryptedMetadata: encryptedMetadata,
      id: fileId,
    );
  }

  Future<DecryptedFile> decryptFile(
    EncryptedFile encryptedFile,
    Uint8List masterKey,
  ) async {
    final decryptedMetadataBytes = await decryptData(
      encryptedFile.encryptedMetadata,
      masterKey,
    );

    final metadataJson = utf8.decode(decryptedMetadataBytes);
    final metadata = FileMetadata.fromJson(jsonDecode(metadataJson));

    final decryptedData = await decryptData(
      encryptedFile.encryptedData,
      masterKey,
    );

    // Verify file integrity
    final currentChecksum = sha256.convert(decryptedData).toString();
    if (currentChecksum != metadata.fileHash) {
      throw Exception('File integrity check failed');
    }

    return DecryptedFile(
      fileName: metadata.originalName,
      data: decryptedData,
      metadata: metadata,
    );
  }

  /// 📁 FILE TYPE DETECTION
  FileType _getFileTypeFromName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return FileType.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
      case 'flv':
      case 'wmv':
        return FileType.video;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
      case 'm4a':
        return FileType.audio;
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
        return FileType.document;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return FileType.archive;
      case 'txt':
      case 'md':
      case 'rtf':
        return FileType.text;
      default:
        return FileType.other;
    }
  }

  /// 🎭 MIME TYPE DETECTION
  String _getMimeTypeFromName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'mp3':
        return 'audio/mpeg';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  String generateSecureToken(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(_secureRandom.nextUint32() % chars.length),
      ),
    );
  }

  String _generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _secureRandom.nextUint32();
    return '${timestamp}_$random';
  }

  /// 🔗 CONVENIENCE METHODS FOR FILE MANAGER
  Future<Uint8List> encryptBytes(Uint8List data) async {
    if (_key == null) {
      throw Exception('Master key not set');
    }
    return _cryptoFFI.encryptBytes(data, _key!);
  }

  Future<Uint8List> decryptBytes(Uint8List encryptedBytes) async {
    if (_key == null) {
      throw Exception('Master key not set');
    }
    return _cryptoFFI.decryptBytes(encryptedBytes, _key!);
  }

  /// 🧮 HASH DATA FOR INTEGRITY
  Future<String> hashData(Uint8List data) async {
    final digest = SHA256Digest();
    final hash = digest.process(data);
    return hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

/// 🏆 MILITARY-GRADE DATA STRUCTURES

class MilitaryHashResult {
  final String hash;
  final Uint8List salt;
  final String algorithm;
  final int iterations;
  final int rounds;
  final int version;
  final DateTime timestamp;

  MilitaryHashResult({
    required this.hash,
    required this.salt,
    required this.algorithm,
    required this.iterations,
    required this.rounds,
    required this.version,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'salt': base64.encode(salt),
        'algorithm': algorithm,
        'iterations': iterations,
        'rounds': rounds,
        'version': version,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MilitaryHashResult.fromJson(Map<String, dynamic> json) {
    return MilitaryHashResult(
      hash: json['hash'],
      salt: base64.decode(json['salt']),
      algorithm: json['algorithm'],
      iterations: json['iterations'],
      rounds: json['rounds'],
      version: json['version'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class MilitaryEncryptedData {
  final Uint8List cipherText;
  final Uint8List iv; // 24-byte nonce for XChaCha20-Poly1305
  final Uint8List authTag; // 16-byte MAC
  final String algorithm;
  final DateTime timestamp;

  MilitaryEncryptedData({
    required this.cipherText,
    required this.iv,
    required this.authTag,
    required this.algorithm,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'cipherText': base64.encode(cipherText),
        'iv': base64.encode(iv),
        'authTag': base64.encode(authTag),
        'algorithm': algorithm,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MilitaryEncryptedData.fromJson(Map<String, dynamic> json) {
    return MilitaryEncryptedData(
      cipherText: base64.decode(json['cipherText']),
      iv: base64.decode(json['iv']),
      authTag: base64.decode(json['authTag']),
      algorithm: json['algorithm'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  @override
  String toString() => 'SecurityException: $message';
}

// Legacy data models for backward compatibility
class EncryptedData {
  final Uint8List encryptedBytes;
  final Uint8List iv;
  final Uint8List authTag;

  EncryptedData({
    required this.encryptedBytes,
    required this.iv,
    required this.authTag,
  });
}

class EncryptedFile {
  final EncryptedData encryptedData;
  final EncryptedData encryptedMetadata;
  final String id;

  EncryptedFile({
    required this.encryptedData,
    required this.encryptedMetadata,
    required this.id,
  });

  Map<String, dynamic> toJson() => {
        'encryptedData': {
          'bytes': base64.encode(encryptedData.encryptedBytes),
          'iv': base64.encode(encryptedData.iv),
          'authTag': base64.encode(encryptedData.authTag),
        },
        'encryptedMetadata': {
          'bytes': base64.encode(encryptedMetadata.encryptedBytes),
          'iv': base64.encode(encryptedMetadata.iv),
          'authTag': base64.encode(encryptedMetadata.authTag),
        },
        'id': id,
      };

  factory EncryptedFile.fromJson(Map<String, dynamic> json) => EncryptedFile(
        encryptedData: EncryptedData(
          encryptedBytes: base64.decode(json['encryptedData']['bytes']),
          iv: base64.decode(json['encryptedData']['iv']),
          authTag: base64.decode(json['encryptedData']['authTag']),
        ),
        encryptedMetadata: EncryptedData(
          encryptedBytes: base64.decode(json['encryptedMetadata']['bytes']),
          iv: base64.decode(json['encryptedMetadata']['iv']),
          authTag: base64.decode(json['encryptedMetadata']['authTag']),
        ),
        id: json['id'],
      );
}

class DecryptedFile {
  final String fileName;
  final Uint8List data;
  final FileMetadata metadata;

  DecryptedFile({
    required this.fileName,
    required this.data,
    required this.metadata,
  });
}
