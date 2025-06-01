/// 🔐 TOTP (TIME-BASED ONE-TIME PASSWORD) SERVICE
///
/// Provides military-grade TOTP authentication with:
/// • RFC 6238 compliant TOTP generation
/// • Backup recovery codes
/// • Anti-replay protection
/// • Time drift tolerance

import 'package:otp/otp.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:notehider/models/security_config.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

class TOTPService {
  // Secure storage for TOTP data
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // TOTP state
  bool _isInitialized = false;
  String? _secretKey;
  List<String> _backupCodes = [];
  Set<String> _usedCodes = {};
  DateTime? _lastCodeTime;

  // Constants
  static const String _secretKeyKey = 'totp_secret_key';
  static const String _backupCodesKey = 'totp_backup_codes';
  static const String _usedCodesKey = 'totp_used_codes';
  static const String _lastCodeTimeKey = 'totp_last_code_time';

  static const int _codeLength = 6;
  static const int _timeStep = 30; // seconds
  static const int _timeDriftTolerance = 1; // allow 1 step before/after
  static const int _backupCodeCount = 10;
  static const int _backupCodeLength = 8;

  /// 🚀 INITIALIZE TOTP SERVICE
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadTOTPData();
      _isInitialized = true;
      print('🔐 TOTP service initialized');
    } catch (e) {
      print('🚨 TOTP service initialization failed: $e');
      rethrow;
    }
  }

  /// 🔑 SETUP TOTP (First time setup)
  Future<TOTPSetupResult> setupTOTP({
    String? customSecret,
    SecurityLevel securityLevel = SecurityLevel.high,
  }) async {
    await _ensureInitialized();

    try {
      // Generate or use provided secret
      _secretKey = customSecret ?? _generateSecretKey(securityLevel);

      // Generate backup codes
      _backupCodes = _generateBackupCodes();

      // Clear used codes
      _usedCodes.clear();
      _lastCodeTime = null;

      // Save to secure storage
      await _saveTOTPData();

      // Generate QR code data for authenticator apps
      final qrCodeData = _generateQRCodeData();

      return TOTPSetupResult(
        success: true,
        secretKey: _secretKey!,
        backupCodes: List.from(_backupCodes),
        qrCodeData: qrCodeData,
        message: 'TOTP setup completed successfully',
      );
    } catch (e) {
      return TOTPSetupResult(
        success: false,
        secretKey: '',
        backupCodes: [],
        qrCodeData: '',
        message: 'TOTP setup failed: $e',
      );
    }
  }

  /// 🔓 VERIFY TOTP CODE
  Future<TOTPVerificationResult> verifyCode(
    String code, {
    SecurityLevel securityLevel = SecurityLevel.high,
    bool allowBackupCode = true,
  }) async {
    await _ensureInitialized();

    if (_secretKey == null) {
      return TOTPVerificationResult(
        success: false,
        codeType: TOTPCodeType.invalid,
        message: 'TOTP not configured',
        remainingBackupCodes: _backupCodes.length,
      );
    }

    try {
      // Clean the code (remove spaces, etc.)
      final cleanCode = code.replaceAll(RegExp(r'\s+'), '');

      // Check if it's a backup code first
      if (allowBackupCode && _backupCodes.contains(cleanCode)) {
        return await _verifyBackupCode(cleanCode);
      }

      // Verify TOTP code
      if (cleanCode.length != _codeLength) {
        return TOTPVerificationResult(
          success: false,
          codeType: TOTPCodeType.invalid,
          message: 'Invalid code length',
          remainingBackupCodes: _backupCodes.length,
        );
      }

      // Check for replay attack
      if (await _isReplayAttack(cleanCode)) {
        return TOTPVerificationResult(
          success: false,
          codeType: TOTPCodeType.replay,
          message: 'Code already used (replay attack detected)',
          remainingBackupCodes: _backupCodes.length,
        );
      }

      // Verify with time drift tolerance
      final isValid = await _verifyTOTPWithDrift(cleanCode, securityLevel);

      if (isValid) {
        // Mark code as used
        await _markCodeAsUsed(cleanCode);

        return TOTPVerificationResult(
          success: true,
          codeType: TOTPCodeType.totp,
          message: 'TOTP verification successful',
          remainingBackupCodes: _backupCodes.length,
        );
      } else {
        return TOTPVerificationResult(
          success: false,
          codeType: TOTPCodeType.invalid,
          message: 'Invalid TOTP code',
          remainingBackupCodes: _backupCodes.length,
        );
      }
    } catch (e) {
      return TOTPVerificationResult(
        success: false,
        codeType: TOTPCodeType.error,
        message: 'TOTP verification failed: $e',
        remainingBackupCodes: _backupCodes.length,
      );
    }
  }

  /// 🔄 GENERATE CURRENT TOTP CODE (for testing/display)
  Future<String?> getCurrentCode() async {
    await _ensureInitialized();

    if (_secretKey == null) return null;

    try {
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return OTP.generateTOTPCodeString(
        _secretKey!,
        currentTime,
        length: _codeLength,
        interval: _timeStep,
        algorithm: Algorithm.SHA1,
      );
    } catch (e) {
      print('🚨 Failed to generate current TOTP code: $e');
      return null;
    }
  }

  /// 📊 GET TOTP STATUS
  TOTPStatus getStatus() {
    return TOTPStatus(
      isConfigured: _secretKey != null,
      backupCodesRemaining: _backupCodes.length,
      usedCodesCount: _usedCodes.length,
      lastCodeTime: _lastCodeTime,
    );
  }

  /// 🔄 REGENERATE BACKUP CODES
  Future<List<String>> regenerateBackupCodes() async {
    await _ensureInitialized();

    _backupCodes = _generateBackupCodes();
    await _saveTOTPData();

    print('🔄 Backup codes regenerated');
    return List.from(_backupCodes);
  }

  /// 🗑️ DISABLE TOTP
  Future<void> disableTOTP() async {
    await _ensureInitialized();

    _secretKey = null;
    _backupCodes.clear();
    _usedCodes.clear();
    _lastCodeTime = null;

    await _clearTOTPData();
    print('🗑️ TOTP disabled');
  }

  // 🔒 PRIVATE METHODS

  /// Generate secret key based on security level
  String _generateSecretKey(SecurityLevel securityLevel) {
    final random = Random.secure();
    int keyLength;

    switch (securityLevel) {
      case SecurityLevel.extreme:
        keyLength = 32; // 256 bits
        break;
      case SecurityLevel.maximum:
        keyLength = 24; // 192 bits
        break;
      case SecurityLevel.high:
        keyLength = 20; // 160 bits (RFC recommended)
        break;
      default:
        keyLength = 16; // 128 bits
        break;
    }

    final bytes = Uint8List(keyLength);
    for (int i = 0; i < keyLength; i++) {
      bytes[i] = random.nextInt(256);
    }

    return base32Encode(bytes);
  }

  /// Generate backup codes
  List<String> _generateBackupCodes() {
    final random = Random.secure();
    final codes = <String>[];

    for (int i = 0; i < _backupCodeCount; i++) {
      String code = '';
      for (int j = 0; j < _backupCodeLength; j++) {
        code += random.nextInt(10).toString();
      }
      codes.add(code);
    }

    return codes;
  }

  /// Generate QR code data for authenticator apps
  String _generateQRCodeData() {
    if (_secretKey == null) return '';

    // Standard TOTP URI format
    return 'otpauth://totp/NoteHider?secret=$_secretKey&issuer=NoteHider&algorithm=SHA1&digits=$_codeLength&period=$_timeStep';
  }

  /// Verify backup code
  Future<TOTPVerificationResult> _verifyBackupCode(String code) async {
    if (_backupCodes.contains(code)) {
      // Remove used backup code
      _backupCodes.remove(code);
      await _saveTOTPData();

      return TOTPVerificationResult(
        success: true,
        codeType: TOTPCodeType.backup,
        message: 'Backup code verification successful',
        remainingBackupCodes: _backupCodes.length,
      );
    }

    return TOTPVerificationResult(
      success: false,
      codeType: TOTPCodeType.invalid,
      message: 'Invalid backup code',
      remainingBackupCodes: _backupCodes.length,
    );
  }

  /// Check for replay attack
  Future<bool> _isReplayAttack(String code) async {
    final codeKey =
        '${code}_${DateTime.now().millisecondsSinceEpoch ~/ (_timeStep * 1000)}';
    return _usedCodes.contains(codeKey);
  }

  /// Mark code as used
  Future<void> _markCodeAsUsed(String code) async {
    final codeKey =
        '${code}_${DateTime.now().millisecondsSinceEpoch ~/ (_timeStep * 1000)}';
    _usedCodes.add(codeKey);
    _lastCodeTime = DateTime.now();

    // Clean old used codes (older than 2 time steps)
    final currentTimeStep =
        DateTime.now().millisecondsSinceEpoch ~/ (_timeStep * 1000);
    _usedCodes.removeWhere((usedCode) {
      final parts = usedCode.split('_');
      if (parts.length != 2) return true;
      final timeStep = int.tryParse(parts[1]) ?? 0;
      return currentTimeStep - timeStep > 2;
    });

    await _saveTOTPData();
  }

  /// Verify TOTP with time drift tolerance
  Future<bool> _verifyTOTPWithDrift(
      String code, SecurityLevel securityLevel) async {
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Adjust tolerance based on security level
    int tolerance = _timeDriftTolerance;
    if (securityLevel == SecurityLevel.extreme) {
      tolerance = 0; // No tolerance for extreme security
    } else if (securityLevel == SecurityLevel.maximum) {
      tolerance = 1;
    }

    // Check current time and tolerance window
    for (int i = -tolerance; i <= tolerance; i++) {
      final timeToCheck = currentTime + (i * _timeStep);
      final expectedCode = OTP.generateTOTPCodeString(
        _secretKey!,
        timeToCheck,
        length: _codeLength,
        interval: _timeStep,
        algorithm: Algorithm.SHA1,
      );

      if (code == expectedCode) {
        return true;
      }
    }

    return false;
  }

  /// Base32 encoding for secret key
  String base32Encode(Uint8List bytes) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    String result = '';
    int buffer = 0;
    int bitsLeft = 0;

    for (int byte in bytes) {
      buffer = (buffer << 8) | byte;
      bitsLeft += 8;

      while (bitsLeft >= 5) {
        result += alphabet[(buffer >> (bitsLeft - 5)) & 31];
        bitsLeft -= 5;
      }
    }

    if (bitsLeft > 0) {
      result += alphabet[(buffer << (5 - bitsLeft)) & 31];
    }

    return result;
  }

  /// Storage methods
  Future<void> _loadTOTPData() async {
    try {
      final secretData = await _secureStorage.read(key: _secretKeyKey);
      _secretKey = secretData;

      final backupData = await _secureStorage.read(key: _backupCodesKey);
      if (backupData != null) {
        final backupList = jsonDecode(backupData) as List;
        _backupCodes = backupList.cast<String>();
      }

      final usedData = await _secureStorage.read(key: _usedCodesKey);
      if (usedData != null) {
        final usedList = jsonDecode(usedData) as List;
        _usedCodes = Set.from(usedList);
      }

      final lastTimeData = await _secureStorage.read(key: _lastCodeTimeKey);
      if (lastTimeData != null) {
        _lastCodeTime = DateTime.parse(lastTimeData);
      }
    } catch (e) {
      print('⚠️ Failed to load TOTP data: $e');
    }
  }

  Future<void> _saveTOTPData() async {
    try {
      if (_secretKey != null) {
        await _secureStorage.write(key: _secretKeyKey, value: _secretKey!);
      }

      await _secureStorage.write(
        key: _backupCodesKey,
        value: jsonEncode(_backupCodes),
      );

      await _secureStorage.write(
        key: _usedCodesKey,
        value: jsonEncode(_usedCodes.toList()),
      );

      if (_lastCodeTime != null) {
        await _secureStorage.write(
          key: _lastCodeTimeKey,
          value: _lastCodeTime!.toIso8601String(),
        );
      }
    } catch (e) {
      print('🚨 Failed to save TOTP data: $e');
    }
  }

  Future<void> _clearTOTPData() async {
    try {
      await _secureStorage.delete(key: _secretKeyKey);
      await _secureStorage.delete(key: _backupCodesKey);
      await _secureStorage.delete(key: _usedCodesKey);
      await _secureStorage.delete(key: _lastCodeTimeKey);
    } catch (e) {
      print('🚨 Failed to clear TOTP data: $e');
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}

/// 🔐 TOTP SETUP RESULT
class TOTPSetupResult {
  final bool success;
  final String secretKey;
  final List<String> backupCodes;
  final String qrCodeData;
  final String message;

  TOTPSetupResult({
    required this.success,
    required this.secretKey,
    required this.backupCodes,
    required this.qrCodeData,
    required this.message,
  });
}

/// 🔓 TOTP VERIFICATION RESULT
class TOTPVerificationResult {
  final bool success;
  final TOTPCodeType codeType;
  final String message;
  final int remainingBackupCodes;

  TOTPVerificationResult({
    required this.success,
    required this.codeType,
    required this.message,
    required this.remainingBackupCodes,
  });
}

/// 📊 TOTP STATUS
class TOTPStatus {
  final bool isConfigured;
  final int backupCodesRemaining;
  final int usedCodesCount;
  final DateTime? lastCodeTime;

  TOTPStatus({
    required this.isConfigured,
    required this.backupCodesRemaining,
    required this.usedCodesCount,
    this.lastCodeTime,
  });
}

/// 🔢 TOTP CODE TYPES
enum TOTPCodeType {
  totp,
  backup,
  invalid,
  replay,
  error,
}
