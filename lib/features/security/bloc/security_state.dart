import 'package:equatable/equatable.dart';
import 'package:notehider/models/security_config.dart';

enum SecurityStatus {
  initializing,
  secure,
  warning,
  compromised,
  emergency,
}

enum DeviceBindingStatus {
  notInitialized,
  initializing,
  bound,
  compromised,
}

enum ThreatLevel {
  none,
  low,
  medium,
  high,
  critical,
  emergency,
}

class SecurityState extends Equatable {
  final SecurityStatus status;
  final DeviceBindingStatus deviceBindingStatus;
  final ThreatLevel threatLevel;
  final double securityScore;
  final bool isDeviceBound;
  final String? deviceFingerprint;
  final Map<String, dynamic> deviceCharacteristics;
  final List<String> activeThreats;
  final List<String> securityLog;
  final SecurityProfile? currentProfile;
  final Map<SecurityFeatureType, SecurityFeatureConfig> securityFeatures;
  final DateTime? lastSecurityAudit;
  final String? errorMessage;

  const SecurityState({
    this.status = SecurityStatus.initializing,
    this.deviceBindingStatus = DeviceBindingStatus.notInitialized,
    this.threatLevel = ThreatLevel.none,
    this.securityScore = 0.0,
    this.isDeviceBound = false,
    this.deviceFingerprint,
    this.deviceCharacteristics = const {},
    this.activeThreats = const [],
    this.securityLog = const [],
    this.currentProfile,
    this.securityFeatures = const {},
    this.lastSecurityAudit,
    this.errorMessage,
  });

  SecurityState copyWith({
    SecurityStatus? status,
    DeviceBindingStatus? deviceBindingStatus,
    ThreatLevel? threatLevel,
    double? securityScore,
    bool? isDeviceBound,
    String? deviceFingerprint,
    Map<String, dynamic>? deviceCharacteristics,
    List<String>? activeThreats,
    List<String>? securityLog,
    SecurityProfile? currentProfile,
    Map<SecurityFeatureType, SecurityFeatureConfig>? securityFeatures,
    DateTime? lastSecurityAudit,
    String? errorMessage,
  }) {
    return SecurityState(
      status: status ?? this.status,
      deviceBindingStatus: deviceBindingStatus ?? this.deviceBindingStatus,
      threatLevel: threatLevel ?? this.threatLevel,
      securityScore: securityScore ?? this.securityScore,
      isDeviceBound: isDeviceBound ?? this.isDeviceBound,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      deviceCharacteristics:
          deviceCharacteristics ?? this.deviceCharacteristics,
      activeThreats: activeThreats ?? this.activeThreats,
      securityLog: securityLog ?? this.securityLog,
      currentProfile: currentProfile ?? this.currentProfile,
      securityFeatures: securityFeatures ?? this.securityFeatures,
      lastSecurityAudit: lastSecurityAudit ?? this.lastSecurityAudit,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        deviceBindingStatus,
        threatLevel,
        securityScore,
        isDeviceBound,
        deviceFingerprint,
        deviceCharacteristics,
        activeThreats,
        securityLog,
        currentProfile,
        securityFeatures,
        lastSecurityAudit,
        errorMessage,
      ];
}
