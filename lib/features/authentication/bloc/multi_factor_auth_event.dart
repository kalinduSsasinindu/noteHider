import 'package:equatable/equatable.dart';

abstract class MultiFactorAuthEvent extends Equatable {
  const MultiFactorAuthEvent();
  @override
  List<Object?> get props => [];
}

class InitializeMultiFactorAuth extends MultiFactorAuthEvent {
  final String securityProfile;
  final Map<String, dynamic> configuration;

  const InitializeMultiFactorAuth({
    required this.securityProfile,
    required this.configuration,
  });

  @override
  List<Object> get props => [securityProfile, configuration];
}

class RequestBiometricAuth extends MultiFactorAuthEvent {
  final String reason;

  const RequestBiometricAuth({this.reason = 'Authentication required'});

  @override
  List<Object> get props => [reason];
}

class VerifyTOTPCode extends MultiFactorAuthEvent {
  final String code;

  const VerifyTOTPCode(this.code);

  @override
  List<Object> get props => [code];
}

class VerifyLocationSecurity extends MultiFactorAuthEvent {
  final double? latitude;
  final double? longitude;

  const VerifyLocationSecurity({this.latitude, this.longitude});

  @override
  List<Object> get props => [latitude ?? 0.0, longitude ?? 0.0];
}

class ResetAuthFactors extends MultiFactorAuthEvent {
  const ResetAuthFactors();
}

class CompleteBiometricAuth extends MultiFactorAuthEvent {
  final bool success;
  const CompleteBiometricAuth(this.success);
  @override
  List<Object> get props => [success];
}

class CompleteTOTPAuth extends MultiFactorAuthEvent {
  final bool success;
  const CompleteTOTPAuth(this.success);
  @override
  List<Object> get props => [success];
}

class CompleteLocationAuth extends MultiFactorAuthEvent {
  final bool success;
  const CompleteLocationAuth(this.success);
  @override
  List<Object> get props => [success];
}
