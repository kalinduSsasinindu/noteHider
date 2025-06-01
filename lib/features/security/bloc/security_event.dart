import 'package:equatable/equatable.dart';
import 'package:notehider/models/security_config.dart';

abstract class SecurityEvent extends Equatable {
  const SecurityEvent();
  @override
  List<Object?> get props => [];
}

class InitializeSecurity extends SecurityEvent {
  const InitializeSecurity();
}

class PerformSecurityAudit extends SecurityEvent {
  const PerformSecurityAudit();
}

class VerifyDeviceIntegrity extends SecurityEvent {
  const VerifyDeviceIntegrity();
}

class InitializeDeviceBinding extends SecurityEvent {
  final String password;
  const InitializeDeviceBinding(this.password);
  @override
  List<Object> get props => [password];
}

class DetectSecurityThreats extends SecurityEvent {
  const DetectSecurityThreats();
}

class TriggerEmergencyProtocol extends SecurityEvent {
  final String reason;
  const TriggerEmergencyProtocol(this.reason);
  @override
  List<Object> get props => [reason];
}

class UpdateSecurityConfig extends SecurityEvent {
  final SecurityProfile profile;
  const UpdateSecurityConfig(this.profile);
  @override
  List<Object> get props => [profile];
}

class ToggleSecurityFeature extends SecurityEvent {
  final SecurityFeatureType feature;
  final bool enabled;
  const ToggleSecurityFeature(this.feature, this.enabled);
  @override
  List<Object> get props => [feature, enabled];
}

class HandleDeviceCompromise extends SecurityEvent {
  final String threatType;
  const HandleDeviceCompromise(this.threatType);
  @override
  List<Object> get props => [threatType];
}

class RefreshSecurityState extends SecurityEvent {
  const RefreshSecurityState();
}

class ClearDeviceBinding extends SecurityEvent {
  const ClearDeviceBinding();
}

class UpdateSessionSecurity extends SecurityEvent {
  const UpdateSessionSecurity();
}

class ExportSecurityConfiguration extends SecurityEvent {
  const ExportSecurityConfiguration();
}

class ImportSecurityConfiguration extends SecurityEvent {
  final Map<String, dynamic> configuration;
  const ImportSecurityConfiguration(this.configuration);
  @override
  List<Object> get props => [configuration];
}
