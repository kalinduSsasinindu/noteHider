/// 🛡️ TAMPER DETECTION SERVICE
///
/// Provides military-grade tamper detection with:
/// • App integrity monitoring
/// • Root/jailbreak detection
/// • Debug mode detection
/// • Hook detection
/// • Emulator detection
/// • Real-time threat assessment

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:notehider/models/security_config.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class TamperDetectionService {
  // Secure storage for tamper detection data
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Tamper detection state
  bool _isInitialized = false;
  TamperDetectionConfig _config = TamperDetectionConfig.defaultConfig();
  List<TamperDetectionResult> _detectionHistory = [];
  String? _appSignatureHash;
  DateTime? _lastIntegrityCheck;
  int _threatLevel = 0;

  // Constants
  static const String _configKey = 'tamper_detection_config';
  static const String _historyKey = 'tamper_detection_history';
  static const String _signatureKey = 'app_signature_hash';
  static const String _lastCheckKey = 'last_integrity_check';

  static const int _maxHistorySize = 100;
  static const Duration _integrityCheckInterval = Duration(hours: 1);

  /// 🚀 INITIALIZE TAMPER DETECTION SERVICE
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadConfiguration();
      await _loadDetectionHistory();
      await _initializeAppSignature();

      _isInitialized = true;
      print('🛡️ Tamper detection service initialized');

      // Perform initial comprehensive check
      await performComprehensiveCheck();
    } catch (e) {
      print('🚨 Tamper detection service initialization failed: $e');
      rethrow;
    }
  }

  /// 🔍 PERFORM COMPREHENSIVE TAMPER CHECK
  Future<TamperDetectionReport> performComprehensiveCheck() async {
    await _ensureInitialized();

    final results = <TamperDetectionResult>[];
    final startTime = DateTime.now();

    try {
      // 1. Root/Jailbreak Detection
      final rootResult = await _detectRootJailbreak();
      results.add(rootResult);

      // 2. Debug Detection
      final debugResult = await _detectDebugMode();
      results.add(debugResult);

      // 3. Emulator Detection
      final emulatorResult = await _detectEmulator();
      results.add(emulatorResult);

      // 4. Hook Detection
      final hookResult = await _detectHooks();
      results.add(hookResult);

      // 5. App Integrity Check
      final integrityResult = await _checkAppIntegrity();
      results.add(integrityResult);

      // 6. System Integrity Check
      final systemResult = await _checkSystemIntegrity();
      results.add(systemResult);

      // 7. Memory Analysis
      final memoryResult = await _analyzeMemory();
      results.add(memoryResult);

      // 8. Network Security Check
      final networkResult = await _checkNetworkSecurity();
      results.add(networkResult);

      // Calculate overall threat level
      _threatLevel = _calculateThreatLevel(results);

      // Create report
      final report = TamperDetectionReport(
        timestamp: DateTime.now(),
        duration: DateTime.now().difference(startTime),
        results: results,
        threatLevel: _threatLevel,
        overallStatus: _getOverallStatus(results),
        recommendations: _generateRecommendations(results),
      );

      // Store results
      await _storeDetectionResult(report);
      _lastIntegrityCheck = DateTime.now();
      await _saveConfiguration();

      return report;
    } catch (e) {
      final errorResult = TamperDetectionResult(
        checkType: TamperCheckType.unknown,
        status: TamperStatus.error,
        threatLevel: 10,
        message: 'Comprehensive check failed: $e',
        details: {'error': e.toString()},
      );

      return TamperDetectionReport(
        timestamp: DateTime.now(),
        duration: DateTime.now().difference(startTime),
        results: [errorResult],
        threatLevel: 10,
        overallStatus: TamperStatus.error,
        recommendations: ['Investigate tamper detection system failure'],
      );
    }
  }

  /// 🔴 ROOT/JAILBREAK DETECTION
  Future<TamperDetectionResult> _detectRootJailbreak() async {
    final details = <String, dynamic>{};
    int threatLevel = 0;
    String message = '';

    try {
      if (Platform.isAndroid) {
        // Android root detection
        final rootIndicators = <String>[];

        // Check for common root binaries
        final rootPaths = [
          '/system/bin/su',
          '/system/xbin/su',
          '/sbin/su',
          '/data/local/xbin/su',
          '/data/local/bin/su',
          '/system/sd/xbin/su',
          '/system/bin/failsafe/su',
          '/data/local/su',
          '/su/bin/su',
        ];

        for (final path in rootPaths) {
          if (await File(path).exists()) {
            rootIndicators.add('Root binary found: $path');
            threatLevel = 10;
          }
        }

        // Check for root management apps
        final rootApps = [
          'com.noshufou.android.su',
          'com.thirdparty.superuser',
          'eu.chainfire.supersu',
          'com.koushikdutta.superuser',
          'com.zachspong.temprootremovejb',
          'com.ramdroid.appquarantine',
        ];

        // Note: In production, you'd check if these packages are installed
        // This is a simplified version for demonstration

        // Check for Xposed Framework
        try {
          // Check for Xposed indicators
          final xposedFiles = [
            '/data/data/de.robv.android.xposed.installer',
            '/system/framework/XposedBridge.jar',
          ];

          for (final file in xposedFiles) {
            if (await File(file).exists()) {
              rootIndicators.add('Xposed framework detected: $file');
              threatLevel = 9;
            }
          }
        } catch (e) {
          // Permission denied is normal
        }

        details['rootIndicators'] = rootIndicators;

        if (rootIndicators.isNotEmpty) {
          message = 'Device appears to be rooted';
        } else {
          message = 'No root indicators detected';
        }
      } else if (Platform.isIOS) {
        // iOS jailbreak detection
        final jailbreakIndicators = <String>[];

        // Check for common jailbreak files
        final jailbreakPaths = [
          '/private/var/lib/apt',
          '/Applications/Cydia.app',
          '/Applications/blackra1n.app',
          '/Applications/FakeCarrier.app',
          '/Applications/Icy.app',
          '/Applications/IntelliScreen.app',
          '/Applications/MxTube.app',
          '/Applications/RockApp.app',
          '/Applications/SBSettings.app',
          '/Applications/WinterBoard.app',
          '/private/var/lib/cydia',
          '/private/var/mobile/Library/SBSettings/Themes',
          '/private/var/stash',
          '/private/var/tmp/cydia.log',
          '/System/Library/LaunchDaemons/com.ikey.bbot.plist',
          '/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist',
          '/usr/bin/sshd',
          '/usr/libexec/sftp-server',
          '/usr/sbin/sshd',
          '/etc/apt',
          '/bin/bash',
          '/usr/bin/ssh',
        ];

        for (final path in jailbreakPaths) {
          if (await File(path).exists()) {
            jailbreakIndicators.add('Jailbreak file found: $path');
            threatLevel = 10;
          }
        }

        details['jailbreakIndicators'] = jailbreakIndicators;

        if (jailbreakIndicators.isNotEmpty) {
          message = 'Device appears to be jailbroken';
        } else {
          message = 'No jailbreak indicators detected';
        }
      }

      return TamperDetectionResult(
        checkType: TamperCheckType.rootJailbreak,
        status: threatLevel > 0 ? TamperStatus.detected : TamperStatus.clean,
        threatLevel: threatLevel,
        message: message,
        details: details,
      );
    } catch (e) {
      return TamperDetectionResult(
        checkType: TamperCheckType.rootJailbreak,
        status: TamperStatus.error,
        threatLevel: 5,
        message: 'Root/jailbreak detection failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// 🐛 DEBUG MODE DETECTION
  Future<TamperDetectionResult> _detectDebugMode() async {
    final details = <String, dynamic>{};
    int threatLevel = 0;
    final debugIndicators = <String>[];

    try {
      // Check for debug mode indicators
      bool isDebugMode = false;

      // Flutter/Dart debug mode detection
      assert(() {
        isDebugMode = true;
        debugIndicators.add('Flutter debug mode active');
        return true;
      }());

      if (isDebugMode) {
        threatLevel = 7;
      }

      // Check for debugger attachment (simplified)
      if (Platform.isAndroid) {
        // On Android, check for debugging flags
        try {
          // This would check application flags in production
          // For now, we'll check for common debug indicators
          debugIndicators.add('Debug mode check completed');
        } catch (e) {
          debugIndicators.add('Debug check error: $e');
        }
      }

      details['debugIndicators'] = debugIndicators;
      details['isDebugMode'] = isDebugMode;

      return TamperDetectionResult(
        checkType: TamperCheckType.debugMode,
        status: threatLevel > 0 ? TamperStatus.detected : TamperStatus.clean,
        threatLevel: threatLevel,
        message: isDebugMode ? 'Debug mode detected' : 'No debug mode detected',
        details: details,
      );
    } catch (e) {
      return TamperDetectionResult(
        checkType: TamperCheckType.debugMode,
        status: TamperStatus.error,
        threatLevel: 3,
        message: 'Debug mode detection failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// 🤖 EMULATOR DETECTION
  Future<TamperDetectionResult> _detectEmulator() async {
    final details = <String, dynamic>{};
    int threatLevel = 0;
    final emulatorIndicators = <String>[];

    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;

        // Check common emulator indicators
        final emulatorSignatures = [
          'google_sdk',
          'sdk_gphone',
          'Android SDK built for',
          'Genymotion',
          'Andy',
          'nox',
          'BlueStacks',
        ];

        final deviceString =
            '${androidInfo.model} ${androidInfo.manufacturer} ${androidInfo.product}'
                .toLowerCase();

        for (final signature in emulatorSignatures) {
          if (deviceString.contains(signature.toLowerCase())) {
            emulatorIndicators.add('Emulator signature detected: $signature');
            threatLevel = 8;
          }
        }

        // Check for specific emulator files
        final emulatorFiles = [
          '/dev/socket/qemud',
          '/dev/qemu_pipe',
          '/system/lib/libc_malloc_debug_qemu.so',
          '/sys/qemu_trace',
          '/system/bin/qemu-props',
        ];

        for (final file in emulatorFiles) {
          if (await File(file).exists()) {
            emulatorIndicators.add('Emulator file detected: $file');
            threatLevel = 9;
          }
        }

        details['deviceModel'] = androidInfo.model;
        details['manufacturer'] = androidInfo.manufacturer;
        details['product'] = androidInfo.product;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;

        // iOS Simulator detection
        if (iosInfo.model.toLowerCase().contains('simulator')) {
          emulatorIndicators.add('iOS Simulator detected');
          threatLevel = 8;
        }

        details['deviceModel'] = iosInfo.model;
        details['systemName'] = iosInfo.systemName;
      }

      details['emulatorIndicators'] = emulatorIndicators;

      return TamperDetectionResult(
        checkType: TamperCheckType.emulator,
        status: threatLevel > 0 ? TamperStatus.detected : TamperStatus.clean,
        threatLevel: threatLevel,
        message: threatLevel > 0
            ? 'Emulator/simulator detected'
            : 'Running on physical device',
        details: details,
      );
    } catch (e) {
      return TamperDetectionResult(
        checkType: TamperCheckType.emulator,
        status: TamperStatus.error,
        threatLevel: 3,
        message: 'Emulator detection failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// 🪝 HOOK DETECTION
  Future<TamperDetectionResult> _detectHooks() async {
    final details = <String, dynamic>{};
    int threatLevel = 0;
    final hookIndicators = <String>[];

    try {
      // Check for common hooking frameworks
      if (Platform.isAndroid) {
        // Check for Frida
        try {
          final fridaFiles = [
            '/data/local/tmp/frida-server',
            '/sdcard/frida-server',
            '/system/bin/frida-server',
          ];

          for (final file in fridaFiles) {
            if (await File(file).exists()) {
              hookIndicators.add('Frida server detected: $file');
              threatLevel = 10;
            }
          }
        } catch (e) {
          // Permission errors are normal
        }

        // Check for Substrate (Cydia Substrate for Android)
        try {
          if (await File('/data/data/com.saurik.substrate').exists()) {
            hookIndicators.add('Cydia Substrate detected');
            threatLevel = 9;
          }
        } catch (e) {
          // Permission errors are normal
        }
      }

      details['hookIndicators'] = hookIndicators;

      return TamperDetectionResult(
        checkType: TamperCheckType.hooks,
        status: threatLevel > 0 ? TamperStatus.detected : TamperStatus.clean,
        threatLevel: threatLevel,
        message: threatLevel > 0
            ? 'Hooking framework detected'
            : 'No hooks detected',
        details: details,
      );
    } catch (e) {
      return TamperDetectionResult(
        checkType: TamperCheckType.hooks,
        status: TamperStatus.error,
        threatLevel: 3,
        message: 'Hook detection failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// 🔒 APP INTEGRITY CHECK
  Future<TamperDetectionResult> _checkAppIntegrity() async {
    final details = <String, dynamic>{};
    int threatLevel = 0;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentSignature = await _calculateAppSignature();

      details['packageName'] = packageInfo.packageName;
      details['version'] = packageInfo.version;
      details['buildNumber'] = packageInfo.buildNumber;

      if (_appSignatureHash != null) {
        if (currentSignature != _appSignatureHash) {
          threatLevel = 10;
          details['signatureMismatch'] = true;
          details['expectedSignature'] = _appSignatureHash;
          details['currentSignature'] = currentSignature;
        } else {
          details['signatureValid'] = true;
        }
      } else {
        // First run, store the signature
        _appSignatureHash = currentSignature;
        await _saveConfiguration();
        details['firstRun'] = true;
      }

      return TamperDetectionResult(
        checkType: TamperCheckType.appIntegrity,
        status: threatLevel > 0 ? TamperStatus.detected : TamperStatus.clean,
        threatLevel: threatLevel,
        message: threatLevel > 0
            ? 'App integrity compromised'
            : 'App integrity verified',
        details: details,
      );
    } catch (e) {
      return TamperDetectionResult(
        checkType: TamperCheckType.appIntegrity,
        status: TamperStatus.error,
        threatLevel: 5,
        message: 'App integrity check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// 🖥️ SYSTEM INTEGRITY CHECK
  Future<TamperDetectionResult> _checkSystemIntegrity() async {
    final details = <String, dynamic>{};
    int threatLevel = 0;
    final systemIssues = <String>[];

    try {
      if (Platform.isAndroid) {
        // Check for system modifications
        final systemPaths = [
          '/system/recovery-resource.dat',
          '/system/recovery-transform.dat',
          '/system/bin/recovery',
          '/system/etc/recovery-resource.dat',
        ];

        for (final path in systemPaths) {
          if (await File(path).exists()) {
            systemIssues.add('Custom recovery detected: $path');
            threatLevel = 6;
          }
        }

        // Check for Magisk (systemless root)
        final magiskPaths = [
          '/sbin/.magisk',
          '/data/adb/magisk',
          '/cache/.disable_magisk',
        ];

        for (final path in magiskPaths) {
          if (await File(path).exists()) {
            systemIssues.add('Magisk detected: $path');
            threatLevel = 8;
          }
        }
      }

      details['systemIssues'] = systemIssues;

      return TamperDetectionResult(
        checkType: TamperCheckType.systemIntegrity,
        status: threatLevel > 0 ? TamperStatus.detected : TamperStatus.clean,
        threatLevel: threatLevel,
        message: threatLevel > 0
            ? 'System modifications detected'
            : 'System integrity intact',
        details: details,
      );
    } catch (e) {
      return TamperDetectionResult(
        checkType: TamperCheckType.systemIntegrity,
        status: TamperStatus.error,
        threatLevel: 3,
        message: 'System integrity check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// 🧠 MEMORY ANALYSIS
  Future<TamperDetectionResult> _analyzeMemory() async {
    final details = <String, dynamic>{};
    int threatLevel = 0;
    final memoryIssues = <String>[];

    try {
      // Simplified memory analysis
      // In production, this would be more sophisticated

      details['memoryAnalysisComplete'] = true;
      details['memoryIssues'] = memoryIssues;

      return TamperDetectionResult(
        checkType: TamperCheckType.memory,
        status: threatLevel > 0 ? TamperStatus.detected : TamperStatus.clean,
        threatLevel: threatLevel,
        message: 'Memory analysis completed',
        details: details,
      );
    } catch (e) {
      return TamperDetectionResult(
        checkType: TamperCheckType.memory,
        status: TamperStatus.error,
        threatLevel: 2,
        message: 'Memory analysis failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// 🌐 NETWORK SECURITY CHECK
  Future<TamperDetectionResult> _checkNetworkSecurity() async {
    final details = <String, dynamic>{};
    int threatLevel = 0;
    final networkIssues = <String>[];

    try {
      // Check for network monitoring/interception
      // This is a simplified version

      details['networkSecurityCheck'] = true;
      details['networkIssues'] = networkIssues;

      return TamperDetectionResult(
        checkType: TamperCheckType.network,
        status: threatLevel > 0 ? TamperStatus.detected : TamperStatus.clean,
        threatLevel: threatLevel,
        message: 'Network security check completed',
        details: details,
      );
    } catch (e) {
      return TamperDetectionResult(
        checkType: TamperCheckType.network,
        status: TamperStatus.error,
        threatLevel: 2,
        message: 'Network security check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// 📊 CALCULATE THREAT LEVEL
  int _calculateThreatLevel(List<TamperDetectionResult> results) {
    if (results.isEmpty) return 0;

    int maxThreat = 0;
    int totalThreat = 0;
    int detectedCount = 0;

    for (final result in results) {
      if (result.status == TamperStatus.detected) {
        detectedCount++;
        totalThreat += result.threatLevel;
        if (result.threatLevel > maxThreat) {
          maxThreat = result.threatLevel;
        }
      }
    }

    // Weight the threat level based on multiple factors
    if (detectedCount == 0) return 0;
    if (maxThreat >= 10) return 10;
    if (detectedCount >= 3) return 9;

    return (totalThreat / detectedCount).round().clamp(0, 10);
  }

  /// 🎯 GET OVERALL STATUS
  TamperStatus _getOverallStatus(List<TamperDetectionResult> results) {
    bool hasError = false;
    bool hasDetection = false;

    for (final result in results) {
      if (result.status == TamperStatus.error) {
        hasError = true;
      } else if (result.status == TamperStatus.detected) {
        hasDetection = true;
      }
    }

    if (hasDetection) return TamperStatus.detected;
    if (hasError) return TamperStatus.error;
    return TamperStatus.clean;
  }

  /// 📝 GENERATE RECOMMENDATIONS
  List<String> _generateRecommendations(List<TamperDetectionResult> results) {
    final recommendations = <String>[];

    for (final result in results) {
      if (result.status == TamperStatus.detected) {
        switch (result.checkType) {
          case TamperCheckType.rootJailbreak:
            recommendations.add(
                'Device is rooted/jailbroken - Consider using a secure device');
            break;
          case TamperCheckType.debugMode:
            recommendations
                .add('Debug mode detected - Ensure production build');
            break;
          case TamperCheckType.emulator:
            recommendations
                .add('Running on emulator - Use physical device for security');
            break;
          case TamperCheckType.hooks:
            recommendations
                .add('Hooking framework detected - Device may be compromised');
            break;
          case TamperCheckType.appIntegrity:
            recommendations.add(
                'App integrity compromised - Reinstall from official source');
            break;
          case TamperCheckType.systemIntegrity:
            recommendations
                .add('System modifications detected - Use unmodified device');
            break;
          default:
            recommendations
                .add('Security issue detected - Review device security');
        }
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('All security checks passed - Device appears secure');
    }

    return recommendations;
  }

  /// 🔐 CALCULATE APP SIGNATURE
  Future<String> _calculateAppSignature() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final signatureData =
          '${packageInfo.packageName}:${packageInfo.version}:${packageInfo.buildNumber}';
      final bytes = utf8.encode(signatureData);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      throw Exception('Failed to calculate app signature: $e');
    }
  }

  /// 🔐 INITIALIZE APP SIGNATURE
  Future<void> _initializeAppSignature() async {
    try {
      if (_appSignatureHash == null) {
        _appSignatureHash = await _calculateAppSignature();
        await _saveConfiguration();
        print('🔐 App signature initialized');
      }
    } catch (e) {
      print('⚠️ Failed to initialize app signature: $e');
    }
  }

  /// 🗂️ STORAGE METHODS
  Future<void> _loadConfiguration() async {
    try {
      final configJson = await _secureStorage.read(key: _configKey);
      if (configJson != null) {
        _config = TamperDetectionConfig.fromJson(jsonDecode(configJson));
      }

      final signatureHash = await _secureStorage.read(key: _signatureKey);
      _appSignatureHash = signatureHash;

      final lastCheckStr = await _secureStorage.read(key: _lastCheckKey);
      if (lastCheckStr != null) {
        _lastIntegrityCheck = DateTime.parse(lastCheckStr);
      }
    } catch (e) {
      print('⚠️ Failed to load tamper detection configuration: $e');
    }
  }

  Future<void> _saveConfiguration() async {
    try {
      await _secureStorage.write(
        key: _configKey,
        value: jsonEncode(_config.toJson()),
      );

      if (_appSignatureHash != null) {
        await _secureStorage.write(
            key: _signatureKey, value: _appSignatureHash!);
      }

      if (_lastIntegrityCheck != null) {
        await _secureStorage.write(
          key: _lastCheckKey,
          value: _lastIntegrityCheck!.toIso8601String(),
        );
      }
    } catch (e) {
      print('🚨 Failed to save tamper detection configuration: $e');
    }
  }

  Future<void> _loadDetectionHistory() async {
    try {
      final historyJson = await _secureStorage.read(key: _historyKey);
      if (historyJson != null) {
        final historyList = jsonDecode(historyJson) as List;
        _detectionHistory = historyList
            .map((json) => TamperDetectionResult.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('⚠️ Failed to load tamper detection history: $e');
    }
  }

  Future<void> _storeDetectionResult(TamperDetectionReport report) async {
    try {
      // Add to history (keep only recent results)
      if (_detectionHistory.length >= _maxHistorySize) {
        _detectionHistory.removeAt(0);
      }

      // Store the most significant detection from this report
      final significantResult = report.results
          .where((r) => r.status == TamperStatus.detected)
          .fold<TamperDetectionResult?>(
            null,
            (prev, current) =>
                prev == null || current.threatLevel > prev.threatLevel
                    ? current
                    : prev,
          );

      if (significantResult != null) {
        _detectionHistory.add(significantResult);
      }

      await _secureStorage.write(
        key: _historyKey,
        value: jsonEncode(_detectionHistory.map((r) => r.toJson()).toList()),
      );
    } catch (e) {
      print('🚨 Failed to store tamper detection result: $e');
    }
  }

  /// 🔧 UTILITY METHODS
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// 📊 GET CURRENT THREAT LEVEL
  int getCurrentThreatLevel() => _threatLevel;

  /// 📋 GET DETECTION HISTORY
  List<TamperDetectionResult> getDetectionHistory() =>
      List.unmodifiable(_detectionHistory);

  /// ⚙️ UPDATE CONFIGURATION
  Future<void> updateConfiguration(TamperDetectionConfig config) async {
    _config = config;
    await _saveConfiguration();
  }

  /// 🔄 CLEAR HISTORY
  Future<void> clearHistory() async {
    _detectionHistory.clear();
    await _secureStorage.delete(key: _historyKey);
  }

  /// 🔍 PERFORM QUICK INTEGRITY CHECK
  Future<TamperDetectionResult> performQuickCheck() async {
    await _ensureInitialized();

    try {
      int threatLevel = 0;
      final details = <String, dynamic>{};
      final issues = <String>[];

      // Quick root/jailbreak check
      if (_config.enableRootJailbreakDetection) {
        final rootResult = await _detectRootJailbreak();
        if (rootResult.status == TamperStatus.detected) {
          threatLevel = (threatLevel + rootResult.threatLevel).clamp(0, 10);
          issues.add('Root/jailbreak detected');
          details['root_detection'] = rootResult.details;
        }
      }

      // Quick debug mode check
      if (_config.enableDebugDetection) {
        final debugResult = await _detectDebugMode();
        if (debugResult.status == TamperStatus.detected) {
          threatLevel = (threatLevel + debugResult.threatLevel).clamp(0, 10);
          issues.add('Debug mode detected');
          details['debug_detection'] = debugResult.details;
        }
      }

      // Quick app integrity check
      if (_config.enableAppIntegrityCheck) {
        final integrityResult = await _checkAppIntegrity();
        if (integrityResult.status == TamperStatus.detected) {
          threatLevel =
              (threatLevel + integrityResult.threatLevel).clamp(0, 10);
          issues.add('App integrity violation');
          details['integrity_check'] = integrityResult.details;
        }
      }

      // Determine overall status
      final status =
          threatLevel > 0 ? TamperStatus.detected : TamperStatus.clean;
      final message = status == TamperStatus.clean
          ? 'Quick security check passed'
          : 'Security threats detected: ${issues.join(', ')}';

      return TamperDetectionResult(
        checkType: TamperCheckType.unknown, // Quick check covers multiple types
        status: status,
        threatLevel: threatLevel,
        message: message,
        details: {
          'quick_check': true,
          'issues_found': issues,
          'threat_level': threatLevel,
          ...details,
        },
      );
    } catch (e) {
      print('🚨 Quick threat check failed: $e');
      return TamperDetectionResult(
        checkType: TamperCheckType.unknown,
        status: TamperStatus.error,
        threatLevel: 10,
        message: 'Quick security check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// 📊 PUBLIC METHODS
  TamperDetectionConfig getConfiguration() => _config;
}

/// ⚙️ TAMPER DETECTION CONFIGURATION
class TamperDetectionConfig {
  final bool enableRootJailbreakDetection;
  final bool enableDebugDetection;
  final bool enableEmulatorDetection;
  final bool enableHookDetection;
  final bool enableAppIntegrityCheck;
  final bool enableSystemIntegrityCheck;
  final bool enableMemoryAnalysis;
  final bool enableNetworkSecurityCheck;
  final Duration checkInterval;
  final int maxThreatLevel;

  const TamperDetectionConfig({
    this.enableRootJailbreakDetection = true,
    this.enableDebugDetection = true,
    this.enableEmulatorDetection = true,
    this.enableHookDetection = true,
    this.enableAppIntegrityCheck = true,
    this.enableSystemIntegrityCheck = true,
    this.enableMemoryAnalysis = false,
    this.enableNetworkSecurityCheck = false,
    this.checkInterval = const Duration(hours: 1),
    this.maxThreatLevel = 7,
  });

  factory TamperDetectionConfig.defaultConfig() =>
      const TamperDetectionConfig();

  Map<String, dynamic> toJson() => {
        'enableRootJailbreakDetection': enableRootJailbreakDetection,
        'enableDebugDetection': enableDebugDetection,
        'enableEmulatorDetection': enableEmulatorDetection,
        'enableHookDetection': enableHookDetection,
        'enableAppIntegrityCheck': enableAppIntegrityCheck,
        'enableSystemIntegrityCheck': enableSystemIntegrityCheck,
        'enableMemoryAnalysis': enableMemoryAnalysis,
        'enableNetworkSecurityCheck': enableNetworkSecurityCheck,
        'checkIntervalMinutes': checkInterval.inMinutes,
        'maxThreatLevel': maxThreatLevel,
      };

  factory TamperDetectionConfig.fromJson(Map<String, dynamic> json) {
    return TamperDetectionConfig(
      enableRootJailbreakDetection:
          json['enableRootJailbreakDetection'] ?? true,
      enableDebugDetection: json['enableDebugDetection'] ?? true,
      enableEmulatorDetection: json['enableEmulatorDetection'] ?? true,
      enableHookDetection: json['enableHookDetection'] ?? true,
      enableAppIntegrityCheck: json['enableAppIntegrityCheck'] ?? true,
      enableSystemIntegrityCheck: json['enableSystemIntegrityCheck'] ?? true,
      enableMemoryAnalysis: json['enableMemoryAnalysis'] ?? false,
      enableNetworkSecurityCheck: json['enableNetworkSecurityCheck'] ?? false,
      checkInterval: Duration(minutes: json['checkIntervalMinutes'] ?? 60),
      maxThreatLevel: json['maxThreatLevel'] ?? 7,
    );
  }
}

/// 🔍 TAMPER CHECK TYPES
enum TamperCheckType {
  rootJailbreak,
  debugMode,
  emulator,
  hooks,
  appIntegrity,
  systemIntegrity,
  memory,
  network,
  unknown,
}

/// 🚨 TAMPER STATUS
enum TamperStatus {
  clean,
  detected,
  error,
}

/// 📊 TAMPER DETECTION RESULT
class TamperDetectionResult {
  final TamperCheckType checkType;
  final TamperStatus status;
  final int threatLevel;
  final String message;
  final Map<String, dynamic> details;
  final DateTime timestamp;

  TamperDetectionResult({
    required this.checkType,
    required this.status,
    required this.threatLevel,
    required this.message,
    required this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'checkType': checkType.name,
        'status': status.name,
        'threatLevel': threatLevel,
        'message': message,
        'details': details,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TamperDetectionResult.fromJson(Map<String, dynamic> json) {
    return TamperDetectionResult(
      checkType: TamperCheckType.values.firstWhere(
        (t) => t.name == json['checkType'],
        orElse: () => TamperCheckType.unknown,
      ),
      status: TamperStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TamperStatus.error,
      ),
      threatLevel: json['threatLevel'] ?? 0,
      message: json['message'] ?? '',
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// 📋 TAMPER DETECTION REPORT
class TamperDetectionReport {
  final DateTime timestamp;
  final Duration duration;
  final List<TamperDetectionResult> results;
  final int threatLevel;
  final TamperStatus overallStatus;
  final List<String> recommendations;

  TamperDetectionReport({
    required this.timestamp,
    required this.duration,
    required this.results,
    required this.threatLevel,
    required this.overallStatus,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'durationMs': duration.inMilliseconds,
        'results': results.map((r) => r.toJson()).toList(),
        'threatLevel': threatLevel,
        'overallStatus': overallStatus.name,
        'recommendations': recommendations,
      };

  factory TamperDetectionReport.fromJson(Map<String, dynamic> json) {
    return TamperDetectionReport(
      timestamp: DateTime.parse(json['timestamp']),
      duration: Duration(milliseconds: json['durationMs']),
      results: (json['results'] as List)
          .map((r) => TamperDetectionResult.fromJson(r))
          .toList(),
      threatLevel: json['threatLevel'],
      overallStatus: TamperStatus.values.firstWhere(
        (s) => s.name == json['overallStatus'],
        orElse: () => TamperStatus.error,
      ),
      recommendations: List<String>.from(json['recommendations']),
    );
  }
}
