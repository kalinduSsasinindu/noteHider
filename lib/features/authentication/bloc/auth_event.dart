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
