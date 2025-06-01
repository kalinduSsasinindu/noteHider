import 'package:equatable/equatable.dart';

enum AuthStatus {
  firstTimeSetup, // No password set yet
  locked, // Password set, but user needs to authenticate
  unlocked, // User authenticated, can access hidden area
  normalMode, // User in regular notes mode
  securityLockdown, // Emergency security lockdown active
  deviceCompromised, // Device integrity compromised
  quantumThreat, // Quantum computing threat detected
  // 🚀 ENHANCED AUTHENTICATION STATES
  securitySetupInProgress, // User is setting up security features
  multiFactorAuthRequired, // User needs to complete additional auth factors
  biometricAuthRequired, // User needs to provide biometric authentication
  totpAuthRequired, // User needs to provide TOTP code
  locationAuthRequired, // User needs location verification
  securitySetupCompleted, // Security setup wizard completed
  // 🔧 SECURITY MANAGEMENT STATES
  securityFeatureConfiguring, // User is configuring a specific feature
  securityFeatureTesting, // Testing a security feature
  securityProfileSwitching, // Switching between security profiles
  securityStatusUpdating, // Updating security configuration
}

/// 🎖️ MILITARY-GRADE SECURITY STATUS
enum SecurityLevel {
  unknown,
  compromised, // 0-3/10
  weak, // 4-5/10
  moderate, // 6-7/10
  strong, // 8-8.5/10
  professional, // 8.6-9.4/10
  militaryGrade, // 9.5-10/10
}

enum DeviceBindingStatus {
  notInitialized,
  initializing,
  bound,
  compromised,
  updating,
}

enum ThreatLevel {
  none,
  low,
  medium,
  high,
  critical,
  emergency,
}

/// 🛡️ COMPREHENSIVE SECURITY METRICS
class SecurityMetrics {
  final SecurityLevel securityLevel;
  final double securityScore; // 0.0 - 10.0
  final DeviceBindingStatus deviceBinding;
  final ThreatLevel threatLevel;
  final int failedAttempts;
  final DateTime? lastSecurityAudit;
  final List<String> activeThreats;
  final Map<String, dynamic> deviceCharacteristics;
  final bool quantumResistant;
  final bool biometricAvailable;
  final bool emergencyProtocolActive;
  // 🔧 INDIVIDUAL FEATURE STATUS
  final String
      currentSecurityProfile; // 'basic', 'professional', 'military', 'paranoid'
  final Map<String, bool> enabledFeatures; // Feature name → enabled status
  final Map<String, Map<String, dynamic>>
      featureConfigurations; // Feature name → configuration
  final Map<String, DateTime> lastFeatureTests; // Feature name → last test time
  final Map<String, String>
      featureStatuses; // Feature name → status ('working', 'failed', 'not_configured')
  final int sessionTimeoutMinutes;
  final bool requireReauthForSensitiveActions;
  final bool enableContinuousMonitoring;

  const SecurityMetrics({
    this.securityLevel = SecurityLevel.unknown,
    this.securityScore = 0.0,
    this.deviceBinding = DeviceBindingStatus.notInitialized,
    this.threatLevel = ThreatLevel.none,
    this.failedAttempts = 0,
    this.lastSecurityAudit,
    this.activeThreats = const [],
    this.deviceCharacteristics = const {},
    this.quantumResistant = false,
    this.biometricAvailable = false,
    this.emergencyProtocolActive = false,
    this.currentSecurityProfile = 'basic',
    this.enabledFeatures = const {},
    this.featureConfigurations = const {},
    this.lastFeatureTests = const {},
    this.featureStatuses = const {},
    this.sessionTimeoutMinutes = 30,
    this.requireReauthForSensitiveActions = false,
    this.enableContinuousMonitoring = false,
  });

  SecurityMetrics copyWith({
    SecurityLevel? securityLevel,
    double? securityScore,
    DeviceBindingStatus? deviceBinding,
    ThreatLevel? threatLevel,
    int? failedAttempts,
    DateTime? lastSecurityAudit,
    List<String>? activeThreats,
    Map<String, dynamic>? deviceCharacteristics,
    bool? quantumResistant,
    bool? biometricAvailable,
    bool? emergencyProtocolActive,
    String? currentSecurityProfile,
    Map<String, bool>? enabledFeatures,
    Map<String, Map<String, dynamic>>? featureConfigurations,
    Map<String, DateTime>? lastFeatureTests,
    Map<String, String>? featureStatuses,
    int? sessionTimeoutMinutes,
    bool? requireReauthForSensitiveActions,
    bool? enableContinuousMonitoring,
  }) {
    return SecurityMetrics(
      securityLevel: securityLevel ?? this.securityLevel,
      securityScore: securityScore ?? this.securityScore,
      deviceBinding: deviceBinding ?? this.deviceBinding,
      threatLevel: threatLevel ?? this.threatLevel,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lastSecurityAudit: lastSecurityAudit ?? this.lastSecurityAudit,
      activeThreats: activeThreats ?? this.activeThreats,
      deviceCharacteristics:
          deviceCharacteristics ?? this.deviceCharacteristics,
      quantumResistant: quantumResistant ?? this.quantumResistant,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      emergencyProtocolActive:
          emergencyProtocolActive ?? this.emergencyProtocolActive,
      currentSecurityProfile:
          currentSecurityProfile ?? this.currentSecurityProfile,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      featureConfigurations:
          featureConfigurations ?? this.featureConfigurations,
      lastFeatureTests: lastFeatureTests ?? this.lastFeatureTests,
      featureStatuses: featureStatuses ?? this.featureStatuses,
      sessionTimeoutMinutes:
          sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      requireReauthForSensitiveActions: requireReauthForSensitiveActions ??
          this.requireReauthForSensitiveActions,
      enableContinuousMonitoring:
          enableContinuousMonitoring ?? this.enableContinuousMonitoring,
    );
  }

  /// Get count of enabled security features
  int get enabledFeaturesCount =>
      enabledFeatures.values.where((enabled) => enabled).length;

  /// Get count of working security features
  int get workingFeaturesCount =>
      featureStatuses.values.where((status) => status == 'working').length;

  /// Check if a specific feature is enabled and working
  bool isFeatureActive(String featureType) {
    return (enabledFeatures[featureType] ?? false) &&
        (featureStatuses[featureType] ?? 'not_configured') == 'working';
  }

  /// Get list of active security features
  List<String> get activeSecurityFeatures {
    return enabledFeatures.entries
        .where((entry) =>
            entry.value &&
            (featureStatuses[entry.key] ?? 'not_configured') == 'working')
        .map((entry) => entry.key)
        .toList();
  }
}

class AuthState extends Equatable {
  final AuthStatus status;
  final bool isPasswordSet;
  final String? errorMessage;

  // 🎖️ MILITARY-GRADE SECURITY ENHANCEMENTS
  final SecurityMetrics securityMetrics;
  final bool isDeviceBound;
  final String? deviceFingerprint;
  final DateTime? lastAuthentication;
  final Map<String, dynamic> securityConfig;
  final List<String> securityLog;

  const AuthState({
    required this.status,
    required this.isPasswordSet,
    this.errorMessage,
    this.securityMetrics = const SecurityMetrics(),
    this.isDeviceBound = false,
    this.deviceFingerprint,
    this.lastAuthentication,
    this.securityConfig = const {},
    this.securityLog = const [],
  });

  const AuthState.initial()
      : status = AuthStatus.firstTimeSetup,
        isPasswordSet = false,
        errorMessage = null,
        securityMetrics = const SecurityMetrics(),
        isDeviceBound = false,
        deviceFingerprint = null,
        lastAuthentication = null,
        securityConfig = const {},
        securityLog = const [];

  AuthState copyWith({
    AuthStatus? status,
    bool? isPasswordSet,
    String? errorMessage,
    SecurityMetrics? securityMetrics,
    bool? isDeviceBound,
    String? deviceFingerprint,
    DateTime? lastAuthentication,
    Map<String, dynamic>? securityConfig,
    List<String>? securityLog,
    Map<String, dynamic>? deviceCharacteristics,
  }) {
    return AuthState(
      status: status ?? this.status,
      isPasswordSet: isPasswordSet ?? this.isPasswordSet,
      errorMessage: errorMessage,
      securityMetrics: securityMetrics ?? this.securityMetrics,
      isDeviceBound: isDeviceBound ?? this.isDeviceBound,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      lastAuthentication: lastAuthentication ?? this.lastAuthentication,
      securityConfig: securityConfig ?? this.securityConfig,
      securityLog: securityLog ?? this.securityLog,
    );
  }

  /// Get human-readable security status
  String get securityStatusText {
    switch (securityMetrics.securityLevel) {
      case SecurityLevel.militaryGrade:
        return '🎖️ MILITARY-GRADE (${securityMetrics.securityScore.toStringAsFixed(1)}/10)';
      case SecurityLevel.professional:
        return '🛡️ PROFESSIONAL (${securityMetrics.securityScore.toStringAsFixed(1)}/10)';
      case SecurityLevel.strong:
        return '🔒 STRONG (${securityMetrics.securityScore.toStringAsFixed(1)}/10)';
      case SecurityLevel.moderate:
        return '🟡 MODERATE (${securityMetrics.securityScore.toStringAsFixed(1)}/10)';
      case SecurityLevel.weak:
        return '⚠️ WEAK (${securityMetrics.securityScore.toStringAsFixed(1)}/10)';
      case SecurityLevel.compromised:
        return '🚨 COMPROMISED (${securityMetrics.securityScore.toStringAsFixed(1)}/10)';
      case SecurityLevel.unknown:
        return '❓ UNKNOWN';
    }
  }

  /// Get threat level indicator
  String get threatIndicator {
    switch (securityMetrics.threatLevel) {
      case ThreatLevel.emergency:
        return '🚨 EMERGENCY';
      case ThreatLevel.critical:
        return '🔴 CRITICAL';
      case ThreatLevel.high:
        return '🟠 HIGH';
      case ThreatLevel.medium:
        return '🟡 MEDIUM';
      case ThreatLevel.low:
        return '🟢 LOW';
      case ThreatLevel.none:
        return '✅ SECURE';
    }
  }

  /// Check if emergency protocols should be active
  bool get shouldActivateEmergency {
    return securityMetrics.threatLevel == ThreatLevel.critical ||
        securityMetrics.threatLevel == ThreatLevel.emergency ||
        securityMetrics.failedAttempts >= 5 ||
        securityMetrics.deviceBinding == DeviceBindingStatus.compromised;
  }

  @override
  List<Object?> get props => [
        status,
        isPasswordSet,
        errorMessage,
        securityMetrics,
        isDeviceBound,
        deviceFingerprint,
        lastAuthentication,
        securityConfig,
        securityLog,
      ];
}
