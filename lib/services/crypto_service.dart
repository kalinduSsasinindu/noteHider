import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/digests/sha3.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/macs/hmac.dart';

class CryptoService {
  static const int _saltLength = 32;
  static const int _keyLength = 32;
  static const int _ivLength = 16;

  final FortunaRandom _secureRandom = FortunaRandom();

  CryptoService() {
    // Initialize secure random with entropy
    _initializeSecureRandom();
  }

  void _initializeSecureRandom() {
    final seed = List<int>.generate(32, (i) => Random.secure().nextInt(256));
    _secureRandom.seed(KeyParameter(Uint8List.fromList(seed)));
  }

  /// Generates a cryptographically secure random salt
  Uint8List generateSalt() {
    return _secureRandom.nextBytes(_saltLength);
  }

  /// Hashes password using PBKDF2 with SHA-256 (secure and compatible)
  Future<String> hashPassword(String password, Uint8List salt) async {
    final passwordBytes = utf8.encode(password);

    // Use PBKDF2 with high iteration count
    final hash = _pbkdf2(passwordBytes, salt, 100000, _keyLength);

    return base64.encode(hash);
  }

  /// Verifies password against stored hash
  Future<bool> verifyPassword(
    String password,
    String storedHash,
    Uint8List salt,
  ) async {
    final newHash = await hashPassword(password, salt);
    return _constantTimeEquals(newHash, storedHash);
  }

  /// Derives master key for file encryption using PBKDF2
  Future<Uint8List> deriveMasterKey(String password, Uint8List salt) async {
    final passwordBytes = utf8.encode(password);
    return _pbkdf2(passwordBytes, salt, 100000, _keyLength);
  }

  /// Manual PBKDF2 implementation using SHA-256
  Uint8List _pbkdf2(
      List<int> password, Uint8List salt, int iterations, int keyLength) {
    final hmac = Hmac(sha256, password);
    final result = <int>[];

    final blocks = (keyLength / 32).ceil();

    for (int i = 1; i <= blocks; i++) {
      final blockSalt = List<int>.from(salt)..addAll(_intToBytes(i));

      var u = hmac.convert(blockSalt).bytes;
      final t = List<int>.from(u);

      for (int j = 1; j < iterations; j++) {
        u = hmac.convert(u).bytes;
        for (int k = 0; k < u.length; k++) {
          t[k] ^= u[k];
        }
      }

      result.addAll(t);
    }

    return Uint8List.fromList(result.take(keyLength).toList());
  }

  /// Convert integer to bytes (big-endian)
  List<int> _intToBytes(int value) {
    return [
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
  }

  /// Encrypts data using AES-256-GCM (Authenticated Encryption)
  Future<EncryptedData> encryptData(Uint8List data, Uint8List masterKey) async {
    final key = Key(masterKey);
    final iv = IV.fromSecureRandom(_ivLength);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

    final encrypted = encrypter.encryptBytes(data, iv: iv);

    return EncryptedData(
      encryptedBytes: encrypted.bytes,
      iv: iv.bytes,
      authTag: encrypted.bytes.sublist(encrypted.bytes.length - 16),
    );
  }

  /// Decrypts data using AES-256-GCM
  Future<Uint8List> decryptData(
      EncryptedData encryptedData, Uint8List masterKey) async {
    final key = Key(masterKey);
    final iv = IV(encryptedData.iv);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

    final encrypted = Encrypted(encryptedData.encryptedBytes);
    final decrypted = encrypter.decryptBytes(encrypted, iv: iv);

    return Uint8List.fromList(decrypted);
  }

  /// Encrypts file content with metadata
  Future<EncryptedFile> encryptFile({
    required String fileName,
    required Uint8List fileData,
    required Uint8List masterKey,
  }) async {
    final metadata = FileMetadata(
      originalName: fileName,
      size: fileData.length,
      timestamp: DateTime.now(),
      checksum: sha256.convert(fileData).toString(),
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
      id: _generateUniqueId(),
    );
  }

  /// Decrypts file with metadata verification
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
    if (currentChecksum != metadata.checksum) {
      throw Exception('File integrity check failed');
    }

    return DecryptedFile(
      fileName: metadata.originalName,
      data: decryptedData,
      metadata: metadata,
    );
  }

  /// Secure random string generation
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

  /// Constant-time string comparison to prevent timing attacks
  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}

// Data models for encryption
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

class FileMetadata {
  final String originalName;
  final int size;
  final DateTime timestamp;
  final String checksum;

  FileMetadata({
    required this.originalName,
    required this.size,
    required this.timestamp,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
        'originalName': originalName,
        'size': size,
        'timestamp': timestamp.toIso8601String(),
        'checksum': checksum,
      };

  factory FileMetadata.fromJson(Map<String, dynamic> json) => FileMetadata(
        originalName: json['originalName'],
        size: json['size'],
        timestamp: DateTime.parse(json['timestamp']),
        checksum: json['checksum'],
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
