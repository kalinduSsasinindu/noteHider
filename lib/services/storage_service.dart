import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _passwordHashKey = 'password_hash';
  static const String _saltKey = 'salt';
  static const String _passwordSetKey = 'password_set';
  static const String _masterKeyKey = 'master_key';
  static const String _notesKey = 'notes_data';
  static const String _encryptedFilesKey = 'encrypted_files';

  // Secure storage for sensitive data
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Regular storage for app state
  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // Authentication related storage
  Future<bool> isPasswordSet() async {
    await initialize();
    return _prefs.getBool(_passwordSetKey) ?? false;
  }

  Future<void> setPasswordSetFlag(bool value) async {
    await initialize();
    await _prefs.setBool(_passwordSetKey, value);
  }

  Future<void> storePasswordHash(String hash) async {
    await _secureStorage.write(key: _passwordHashKey, value: hash);
  }

  Future<String?> getPasswordHash() async {
    return await _secureStorage.read(key: _passwordHashKey);
  }

  Future<void> storeSalt(Uint8List salt) async {
    final saltBase64 = base64.encode(salt);
    await _secureStorage.write(key: _saltKey, value: saltBase64);
  }

  Future<Uint8List?> getSalt() async {
    final saltBase64 = await _secureStorage.read(key: _saltKey);
    if (saltBase64 == null) return null;
    return base64.decode(saltBase64);
  }

  Future<void> storeMasterKey(Uint8List masterKey) async {
    final keyBase64 = base64.encode(masterKey);
    await _secureStorage.write(key: _masterKeyKey, value: keyBase64);
  }

  Future<Uint8List?> getMasterKey() async {
    final keyBase64 = await _secureStorage.read(key: _masterKeyKey);
    if (keyBase64 == null) return null;
    return base64.decode(keyBase64);
  }

  // Notes storage
  Future<void> storeNotes(List<Note> notes) async {
    await initialize();
    final notesJson = notes.map((note) => note.toJson()).toList();
    final notesString = jsonEncode(notesJson);
    await _prefs.setString(_notesKey, notesString);
  }

  Future<List<Note>> getNotes() async {
    await initialize();
    final notesString = _prefs.getString(_notesKey);
    if (notesString == null) return [];

    final notesJson = jsonDecode(notesString) as List;
    return notesJson.map((json) => Note.fromJson(json)).toList();
  }

  // Encrypted files storage
  Future<void> storeEncryptedFiles(List<Map<String, dynamic>> files) async {
    final filesString = jsonEncode(files);
    await _secureStorage.write(key: _encryptedFilesKey, value: filesString);
  }

  Future<List<Map<String, dynamic>>> getEncryptedFiles() async {
    final filesString = await _secureStorage.read(key: _encryptedFilesKey);
    if (filesString == null) return [];

    final filesJson = jsonDecode(filesString) as List;
    return filesJson.cast<Map<String, dynamic>>();
  }

  // Security operations
  Future<void> clearSessionData() async {
    // Clear sensitive data from memory but keep persistent data
    await _secureStorage.delete(key: _masterKeyKey);
  }

  Future<void> clearAllData() async {
    await initialize();

    // Clear all secure storage
    await _secureStorage.deleteAll();

    // Clear all shared preferences
    await _prefs.clear();
  }

  // Backup and restore
  Future<String> exportBackupData() async {
    final passwordHash = await getPasswordHash();
    final salt = await getSalt();
    final notes = await getNotes();
    final encryptedFiles = await getEncryptedFiles();

    final backupData = {
      'passwordHash': passwordHash,
      'salt': salt != null ? base64.encode(salt) : null,
      'notes': notes.map((note) => note.toJson()).toList(),
      'encryptedFiles': encryptedFiles,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(backupData);
  }

  Future<bool> importBackupData(String backupJson) async {
    try {
      final backupData = jsonDecode(backupJson);

      if (backupData['passwordHash'] != null) {
        await storePasswordHash(backupData['passwordHash']);
      }

      if (backupData['salt'] != null) {
        final salt = base64.decode(backupData['salt']);
        await storeSalt(salt);
      }

      if (backupData['notes'] != null) {
        final notes = (backupData['notes'] as List)
            .map((json) => Note.fromJson(json))
            .toList();
        await storeNotes(notes);
      }

      if (backupData['encryptedFiles'] != null) {
        await storeEncryptedFiles(
          (backupData['encryptedFiles'] as List).cast<Map<String, dynamic>>(),
        );
      }

      await setPasswordSetFlag(true);
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Note model for regular notes (disguise)
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPasswordNote; // Special flag for password notes

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isPasswordNote = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isPasswordNote': isPasswordNote,
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        isPasswordNote: json['isPasswordNote'] ?? false,
      );

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPasswordNote,
  }) =>
      Note(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isPasswordNote: isPasswordNote ?? this.isPasswordNote,
      );
}
