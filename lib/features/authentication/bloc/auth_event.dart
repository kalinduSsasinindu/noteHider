import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class CheckFirstTimeSetup extends AuthEvent {
  const CheckFirstTimeSetup();
}

class SetupPassword extends AuthEvent {
  final String password;

  const SetupPassword(this.password);

  @override
  List<Object> get props => [password];
}

class VerifyPassword extends AuthEvent {
  final String password;

  const VerifyPassword(this.password);

  @override
  List<Object> get props => [password];
}

class LockApp extends AuthEvent {
  const LockApp();
}

class ResetApp extends AuthEvent {
  const ResetApp();
}

class ClearAuthData extends AuthEvent {
  const ClearAuthData();
}

// 🎖️ MILITARY-GRADE SECURITY EVENTS

/// Verify device integrity and binding
class VerifyDeviceIntegrity extends AuthEvent {
  const VerifyDeviceIntegrity();
}

/// Perform comprehensive security audit
class PerformSecurityAudit extends AuthEvent {
  const PerformSecurityAudit();
}

/// Initialize military-grade device binding
class InitializeDeviceBinding extends AuthEvent {
  final String password;

  const InitializeDeviceBinding(this.password);

  @override
  List<Object> get props => [password];
}

/// Detect and respond to security threats
class DetectSecurityThreats extends AuthEvent {
  const DetectSecurityThreats();
}

/// Trigger emergency security protocol
class TriggerEmergencyProtocol extends AuthEvent {
  final String reason;

  const TriggerEmergencyProtocol(this.reason);

  @override
  List<Object> get props => [reason];
}

/// Refresh security state and metrics
class RefreshSecurityState extends AuthEvent {
  const RefreshSecurityState();
}

/// Authenticate with biometric data (future enhancement)
class BiometricAuthentication extends AuthEvent {
  const BiometricAuthentication();
}

/// Handle device compromise detection
class HandleDeviceCompromise extends AuthEvent {
  final String threatType;

  const HandleDeviceCompromise(this.threatType);

  @override
  List<Object> get props => [threatType];
}

/// Update security configuration
class UpdateSecurityConfig extends AuthEvent {
  final Map<String, dynamic> config;

  const UpdateSecurityConfig(this.config);

  @override
  List<Object> get props => [config];
}

/// Verify quantum resistance status
class VerifyQuantumResistance extends AuthEvent {
  const VerifyQuantumResistance();
}

/// Clear device binding data (for troubleshooting)
class ClearDeviceBinding extends AuthEvent {
  const ClearDeviceBinding();
}

// 🚀 ENHANCED MULTI-FACTOR AUTHENTICATION EVENTS

/// Setup multi-factor authentication for new users
class SetupMultiFactorAuth extends AuthEvent {
  final String
      securityProfile; // 'basic', 'professional', 'military', 'paranoid'
  final Map<String, dynamic> configuration;

  const SetupMultiFactorAuth({
    required this.securityProfile,
    required this.configuration,
  });

  @override
  List<Object> get props => [securityProfile, configuration];
}

/// Enhanced verification with multiple security factors
class VerifyEnhancedAuth extends AuthEvent {
  final String password;
  final String? biometricData;
  final String? totpCode;
  final Map<String, dynamic>? locationData;
  final bool skipOptionalFactors;

  const VerifyEnhancedAuth({
    required this.password,
    this.biometricData,
    this.totpCode,
    this.locationData,
    this.skipOptionalFactors = false,
  });

  @override
  List<Object> get props => [
        password,
        biometricData ?? '',
        totpCode ?? '',
        locationData ?? {},
        skipOptionalFactors
      ];
}

/// Request biometric authentication
class RequestBiometricAuth extends AuthEvent {
  final String reason;

  const RequestBiometricAuth({this.reason = 'Authentication required'});

  @override
  List<Object> get props => [reason];
}

/// Verify TOTP code
class VerifyTOTPCode extends AuthEvent {
  final String code;

  const VerifyTOTPCode(this.code);

  @override
  List<Object> get props => [code];
}

/// Verify location for location-based security
class VerifyLocationSecurity extends AuthEvent {
  final double? latitude;
  final double? longitude;

  const VerifyLocationSecurity({this.latitude, this.longitude});

  @override
  List<Object> get props => [latitude ?? 0.0, longitude ?? 0.0];
}

/// Update security profile configuration
class UpdateSecurityProfile extends AuthEvent {
  final String profileType; // 'basic', 'professional', 'military', 'paranoid'
  final Map<String, dynamic> configuration;

  const UpdateSecurityProfile({
    required this.profileType,
    required this.configuration,
  });

  @override
  List<Object> get props => [profileType, configuration];
}

/// Skip optional security setup (for basic users)
class SkipSecuritySetup extends AuthEvent {
  const SkipSecuritySetup();
}

/// Complete security setup wizard
class CompleteSecuritySetup extends AuthEvent {
  const CompleteSecuritySetup();
}

// 🔧 INDIVIDUAL SECURITY FEATURE MANAGEMENT

/// Toggle a specific security feature on/off
class ToggleSecurityFeature extends AuthEvent {
  final String
      featureType; // 'biometric', 'location', 'totp', 'tamper_detection', etc.
  final bool enabled;
  final Map<String, dynamic>? configuration;

  const ToggleSecurityFeature({
    required this.featureType,
    required this.enabled,
    this.configuration,
  });

  @override
  List<Object> get props => [featureType, enabled, configuration ?? {}];
}

/// Configure a specific security feature
class ConfigureSecurityFeature extends AuthEvent {
  final String featureType;
  final Map<String, dynamic> configuration;

  const ConfigureSecurityFeature({
    required this.featureType,
    required this.configuration,
  });

  @override
  List<Object> get props => [featureType, configuration];
}

/// Test a security feature to ensure it's working
class TestSecurityFeature extends AuthEvent {
  final String featureType;

  const TestSecurityFeature(this.featureType);

  @override
  List<Object> get props => [featureType];
}

/// Switch to a different security profile (basic → professional → military → paranoid)
class SwitchSecurityProfile extends AuthEvent {
  final String newProfileType;
  final bool
      keepExistingConfig; // Whether to preserve current individual settings

  const SwitchSecurityProfile({
    required this.newProfileType,
    this.keepExistingConfig = true,
  });

  @override
  List<Object> get props => [newProfileType, keepExistingConfig];
}

/// Reset security configuration to defaults
class ResetSecurityConfiguration extends AuthEvent {
  final String profileType; // Which profile's defaults to use

  const ResetSecurityConfiguration({this.profileType = 'basic'});

  @override
  List<Object> get props => [profileType];
}

/// Enable/disable emergency protocols
class ToggleEmergencyProtocols extends AuthEvent {
  final bool enabled;
  final Map<String, dynamic>? emergencyConfig;

  const ToggleEmergencyProtocols({
    required this.enabled,
    this.emergencyConfig,
  });

  @override
  List<Object> get props => [enabled, emergencyConfig ?? {}];
}

/// Update session security settings
class UpdateSessionSecurity extends AuthEvent {
  final int? sessionTimeoutMinutes;
  final bool? requireReauthForSensitiveActions;
  final bool? enableContinuousMonitoring;

  const UpdateSessionSecurity({
    this.sessionTimeoutMinutes,
    this.requireReauthForSensitiveActions,
    this.enableContinuousMonitoring,
  });

  @override
  List<Object> get props => [
        sessionTimeoutMinutes ?? 0,
        requireReauthForSensitiveActions ?? false,
        enableContinuousMonitoring ?? false,
      ];
}

/// Request current security configuration status
class RequestSecurityStatus extends AuthEvent {
  const RequestSecurityStatus();
}

/// Export security configuration (for backup)
class ExportSecurityConfiguration extends AuthEvent {
  const ExportSecurityConfiguration();
}

/// Import security configuration (from backup)
class ImportSecurityConfiguration extends AuthEvent {
  final Map<String, dynamic> configuration;

  const ImportSecurityConfiguration(this.configuration);

  @override
  List<Object> get props => [configuration];
}
