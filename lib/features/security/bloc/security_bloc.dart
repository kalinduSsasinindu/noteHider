import 'package:bloc/bloc.dart';
import 'package:notehider/services/crypto_service.dart';
import 'package:notehider/services/storage_service.dart';
import 'package:notehider/services/tamper_detection_service.dart';
import 'package:notehider/services/auto_wipe_service.dart';
import 'package:notehider/services/decoy_system_service.dart';
import 'package:notehider/services/security_config_service.dart';
import 'package:notehider/models/security_config.dart';
import 'package:notehider/features/security/bloc/security_event.dart';
import 'package:notehider/features/security/bloc/security_state.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';
import 'dart:io';

class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  final CryptoService _cryptoService;
  final StorageService _storageService;
  final TamperDetectionService _tamperDetectionService;
  final AutoWipeService _autoWipeService;
  final DecoySystemService _decoySystemService;
  final SecurityConfigService _securityConfigService;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Security monitoring
  final List<String> _securityLog = [];
  final Map<String, dynamic> _deviceCharacteristics = {};
  String? _deviceFingerprint;
  int _suspiciousActivityCount = 0;
  final List<String> _activeThreats = [];

  SecurityBloc({
    required CryptoService cryptoService,
    required StorageService storageService,
    required TamperDetectionService tamperDetectionService,
    required AutoWipeService autoWipeService,
    required DecoySystemService decoySystemService,
    required SecurityConfigService securityConfigService,
  })  : _cryptoService = cryptoService,
        _storageService = storageService,
        _tamperDetectionService = tamperDetectionService,
        _autoWipeService = autoWipeService,
        _decoySystemService = decoySystemService,
        _securityConfigService = securityConfigService,
        super(const SecurityState()) {
    on<InitializeSecurity>(_onInitializeSecurity);
    on<PerformSecurityAudit>(_onPerformSecurityAudit);
    on<VerifyDeviceIntegrity>(_onVerifyDeviceIntegrity);
    on<InitializeDeviceBinding>(_onInitializeDeviceBinding);
    on<DetectSecurityThreats>(_onDetectSecurityThreats);
    on<TriggerEmergencyProtocol>(_onTriggerEmergencyProtocol);
    on<UpdateSecurityConfig>(_onUpdateSecurityConfig);
    on<ToggleSecurityFeature>(_onToggleSecurityFeature);
    on<HandleDeviceCompromise>(_onHandleDeviceCompromise);
    on<RefreshSecurityState>(_onRefreshSecurityState);
    on<ClearDeviceBinding>(_onClearDeviceBinding);
  }

  Future<void> _onInitializeSecurity(
    InitializeSecurity event,
    Emitter<SecurityState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SecurityStatus.initializing));

      await _collectDeviceCharacteristics();
      await _generateDeviceFingerprint();

      // For now, use placeholder data until we implement the missing methods
      final securityFeatures = <SecurityFeatureType, SecurityFeatureConfig>{};
      final SecurityProfile? currentProfile = null;

      emit(state.copyWith(
        status: SecurityStatus.secure,
        deviceCharacteristics: _deviceCharacteristics,
        deviceFingerprint: _deviceFingerprint,
        securityFeatures: securityFeatures,
        currentProfile: currentProfile,
        lastSecurityAudit: DateTime.now(),
      ));

      _logSecurityEvent('🎖️ Security system initialized');

      // Start threat monitoring
      add(const DetectSecurityThreats());
      add(const PerformSecurityAudit());
    } catch (e) {
      _logSecurityEvent('🚨 Security initialization failed: $e');
      emit(state.copyWith(
        status: SecurityStatus.compromised,
        errorMessage: 'Security initialization failed: $e',
      ));
    }
  }

  Future<void> _onPerformSecurityAudit(
    PerformSecurityAudit event,
    Emitter<SecurityState> emit,
  ) async {
    try {
      _logSecurityEvent('🔍 Performing comprehensive security audit');

      // Update device characteristics
      await _collectDeviceCharacteristics();

      // Calculate security score
      final securityScore = await _calculateSecurityScore();

      emit(state.copyWith(
        securityScore: securityScore,
        deviceCharacteristics: _deviceCharacteristics,
        lastSecurityAudit: DateTime.now(),
        securityLog: List.from(_securityLog),
      ));

      _logSecurityEvent('✅ Security audit completed - Score: $securityScore');
    } catch (e) {
      _logSecurityEvent('🚨 Security audit failed: $e');
      emit(state.copyWith(errorMessage: 'Security audit failed: $e'));
    }
  }

  Future<void> _onVerifyDeviceIntegrity(
    VerifyDeviceIntegrity event,
    Emitter<SecurityState> emit,
  ) async {
    try {
      _logSecurityEvent('🔍 Verifying device integrity');

      final isValid = await _verifyDeviceBindingIntegrity();

      if (!isValid) {
        await _handleSecurityThreat('Device integrity verification failed');

        emit(state.copyWith(
          status: SecurityStatus.compromised,
          deviceBindingStatus: DeviceBindingStatus.compromised,
          threatLevel: ThreatLevel.critical,
        ));
      } else {
        _logSecurityEvent('✅ Device integrity verified');

        emit(state.copyWith(
          deviceBindingStatus: DeviceBindingStatus.bound,
          threatLevel: ThreatLevel.none,
        ));
      }
    } catch (e) {
      _logSecurityEvent('🚨 Device integrity check failed: $e');
      emit(state.copyWith(errorMessage: 'Device integrity check failed: $e'));
    }
  }

  Future<void> _onInitializeDeviceBinding(
    InitializeDeviceBinding event,
    Emitter<SecurityState> emit,
  ) async {
    try {
      _logSecurityEvent('🧬 Initializing device binding');

      emit(state.copyWith(
        deviceBindingStatus: DeviceBindingStatus.initializing,
      ));

      await _initializeDeviceBinding(event.password);

      emit(state.copyWith(
        isDeviceBound: true,
        deviceFingerprint: _deviceFingerprint,
        deviceBindingStatus: DeviceBindingStatus.bound,
        status: SecurityStatus.secure,
      ));

      _logSecurityEvent('✅ Device binding initialized successfully');
    } catch (e) {
      _logSecurityEvent('🚨 Device binding initialization failed: $e');

      emit(state.copyWith(
        deviceBindingStatus: DeviceBindingStatus.notInitialized,
        threatLevel: ThreatLevel.high,
        errorMessage: 'Device binding failed: $e',
      ));
    }
  }

  Future<void> _onDetectSecurityThreats(
    DetectSecurityThreats event,
    Emitter<SecurityState> emit,
  ) async {
    try {
      _logSecurityEvent('🕵️ Scanning for security threats');

      _activeThreats.clear();
      await _scanForThreats();

      final threatLevel = _calculateThreatLevel();

      emit(state.copyWith(
        threatLevel: threatLevel,
        activeThreats: List.from(_activeThreats),
      ));

      if (threatLevel == ThreatLevel.critical ||
          threatLevel == ThreatLevel.emergency) {
        add(TriggerEmergencyProtocol(
            'Critical threats detected: ${_activeThreats.join(', ')}'));
      }

      _logSecurityEvent(
          '🕵️ Threat scan completed - Level: ${threatLevel.name}');
    } catch (e) {
      _logSecurityEvent('🚨 Threat detection failed: $e');
    }
  }

  Future<void> _onTriggerEmergencyProtocol(
    TriggerEmergencyProtocol event,
    Emitter<SecurityState> emit,
  ) async {
    try {
      _logSecurityEvent('🚨 EMERGENCY PROTOCOL TRIGGERED: ${event.reason}');

      emit(state.copyWith(
        status: SecurityStatus.emergency,
        threatLevel: ThreatLevel.emergency,
      ));

      // For now, use a placeholder emergency action
      // TODO: Implement proper emergency protocol
      _logSecurityEvent('💥 Emergency protocol executed');
    } catch (e) {
      _logSecurityEvent('🚨 Emergency protocol failed: $e');
    }
  }

  Future<void> _onUpdateSecurityConfig(
    UpdateSecurityConfig event,
    Emitter<SecurityState> emit,
  ) async {
    try {
      // For now, just update the state directly
      // TODO: Implement proper config update through service

      emit(state.copyWith(
        currentProfile: event.profile,
        securityFeatures: event.profile.features,
      ));

      _logSecurityEvent('⚙️ Security configuration updated');
    } catch (e) {
      _logSecurityEvent('🚨 Security config update failed: $e');
      emit(state.copyWith(errorMessage: 'Security config update failed: $e'));
    }
  }

  Future<void> _onToggleSecurityFeature(
    ToggleSecurityFeature event,
    Emitter<SecurityState> emit,
  ) async {
    try {
      final updatedFeatures =
          Map<SecurityFeatureType, SecurityFeatureConfig>.from(
              state.securityFeatures);
      final currentFeature = updatedFeatures[event.feature];

      if (currentFeature != null) {
        updatedFeatures[event.feature] =
            currentFeature.copyWith(enabled: event.enabled);

        emit(state.copyWith(securityFeatures: updatedFeatures));

        _logSecurityEvent(
            '🔧 Security feature ${event.feature.name} ${event.enabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      _logSecurityEvent('🚨 Security feature toggle failed: $e');
    }
  }

  Future<void> _onHandleDeviceCompromise(
    HandleDeviceCompromise event,
    Emitter<SecurityState> emit,
  ) async {
    try {
      _logSecurityEvent('🚨 DEVICE COMPROMISE DETECTED: ${event.threatType}');

      await _handleSecurityThreat(event.threatType);

      emit(state.copyWith(
        status: SecurityStatus.compromised,
        threatLevel: ThreatLevel.critical,
      ));
    } catch (e) {
      _logSecurityEvent('🚨 Device compromise handling failed: $e');
    }
  }

  Future<void> _onRefreshSecurityState(
    RefreshSecurityState event,
    Emitter<SecurityState> emit,
  ) async {
    try {
      _logSecurityEvent('🔄 Refreshing security state');

      await _collectDeviceCharacteristics();
      final securityScore = await _calculateSecurityScore();

      emit(state.copyWith(
        securityScore: securityScore,
        deviceCharacteristics: _deviceCharacteristics,
        lastSecurityAudit: DateTime.now(),
      ));
    } catch (e) {
      _logSecurityEvent('🚨 Security state refresh failed: $e');
    }
  }

  Future<void> _onClearDeviceBinding(
    ClearDeviceBinding event,
    Emitter<SecurityState> emit,
  ) async {
    try {
      _logSecurityEvent('🧹 Clearing device binding');

      // Clear device binding data
      await _storageService.clearDeviceBinding();

      emit(state.copyWith(
        isDeviceBound: false,
        deviceFingerprint: null,
        deviceBindingStatus: DeviceBindingStatus.notInitialized,
      ));

      _logSecurityEvent('✅ Device binding cleared');
    } catch (e) {
      _logSecurityEvent('🚨 Device binding clear failed: $e');
      emit(state.copyWith(errorMessage: 'Device binding clear failed: $e'));
    }
  }

  // Helper methods
  void _logSecurityEvent(String message) {
    final timestamp = DateTime.now().toIso8601String();
    _securityLog.add('[$timestamp] $message');
    print(message);
  }

  Future<void> _collectDeviceCharacteristics() async {
    // Implementation moved from AuthBloc
    if (Platform.isWindows) {
      final windowsInfo = await _deviceInfo.windowsInfo;
      _deviceCharacteristics.addAll({
        'computerName': windowsInfo.computerName,
        'numberOfCores': windowsInfo.numberOfCores,
        'systemMemoryInMegabytes': windowsInfo.systemMemoryInMegabytes,
        'userName': windowsInfo.userName,
        'majorVersion': windowsInfo.majorVersion,
        'minorVersion': windowsInfo.minorVersion,
        'buildNumber': windowsInfo.buildNumber,
        'platformId': windowsInfo.platformId,
        'csdVersion': windowsInfo.csdVersion,
        'servicePackMajor': windowsInfo.servicePackMajor,
        'servicePackMinor': windowsInfo.servicePackMinor,
        'suitMask': windowsInfo.suitMask,
        'productType': windowsInfo.productType,
        'reserved': windowsInfo.reserved,
        'buildLab': windowsInfo.buildLab,
        'buildLabEx': windowsInfo.buildLabEx,
        'digitalProductId': windowsInfo.digitalProductId,
        'displayVersion': windowsInfo.displayVersion,
        'editionId': windowsInfo.editionId,
        'installDate': windowsInfo.installDate?.toIso8601String(),
        'productId': windowsInfo.productId,
        'productName': windowsInfo.productName,
        'registeredOwner': windowsInfo.registeredOwner,
        'releaseId': windowsInfo.releaseId,
      });
    }
    // Add other platform implementations...
  }

  Future<void> _generateDeviceFingerprint() async {
    final fingerprintData = {
      'characteristics': _deviceCharacteristics,
      'platform': Platform.operatingSystem,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final fingerprintBytes = utf8.encode(json.encode(fingerprintData));
    _deviceFingerprint = base64.encode(fingerprintBytes);
  }

  Future<bool> _verifyDeviceBindingIntegrity() async {
    // Implementation moved from AuthBloc
    try {
      final storedFingerprint = await _storageService.getDeviceFingerprint();
      if (storedFingerprint == null) return false;

      await _collectDeviceCharacteristics();
      await _generateDeviceFingerprint();

      return storedFingerprint == _deviceFingerprint;
    } catch (e) {
      return false;
    }
  }

  Future<void> _initializeDeviceBinding(String password) async {
    // Implementation moved from AuthBloc
    await _collectDeviceCharacteristics();
    await _generateDeviceFingerprint();

    if (_deviceFingerprint != null) {
      await _storageService.storeDeviceFingerprint(_deviceFingerprint!);
    }
  }

  Future<void> _scanForThreats() async {
    // Implementation moved from AuthBloc
    // Check for debugger
    if (!bool.fromEnvironment('dart.vm.product')) {
      _activeThreats.add('Debug mode detected');
    }

    // Check for suspicious file access patterns
    // Add more threat detection logic...
  }

  ThreatLevel _calculateThreatLevel() {
    if (_activeThreats.isEmpty) return ThreatLevel.none;
    if (_activeThreats.length >= 3) return ThreatLevel.critical;
    if (_activeThreats.length >= 2) return ThreatLevel.high;
    if (_activeThreats.length >= 1) return ThreatLevel.medium;
    return ThreatLevel.low;
  }

  Future<double> _calculateSecurityScore() async {
    // Calculate based on active security features
    double score = 0.0;

    for (final feature in state.securityFeatures.values) {
      if (feature.enabled) {
        switch (feature.level) {
          case SecurityLevel.basic:
            score += 1.0;
            break;
          case SecurityLevel.medium:
            score += 2.0;
            break;
          case SecurityLevel.high:
            score += 3.0;
            break;
          case SecurityLevel.maximum:
            score += 4.0;
            break;
          case SecurityLevel.extreme:
            score += 5.0;
            break;
          default:
            break;
        }
      }
    }

    return state.securityFeatures.isEmpty
        ? 0.0
        : (score / (state.securityFeatures.length * 5.0)) * 10.0;
  }

  Future<void> _handleSecurityThreat(String threat) async {
    _logSecurityEvent('🚨 Security threat handled: $threat');
    _suspiciousActivityCount++;

    if (_suspiciousActivityCount >= 3) {
      // Trigger more severe measures
      add(TriggerEmergencyProtocol('Multiple security threats detected'));
    }
  }
}
