import 'package:equatable/equatable.dart';

enum MultiFactorAuthStatus {
  initial,
  configuring,
  awaitingFactors,
  biometricRequired,
  totpRequired,
  locationRequired,
  completed,
  failed,
}

class MultiFactorAuthState extends Equatable {
  final MultiFactorAuthStatus status;
  final Set<String> completedFactors;
  final Set<String> requiredFactors;
  final bool biometricAvailable;
  final bool totpConfigured;
  final bool locationRequired;
  final String? errorMessage;
  final String? currentSecurityProfile;

  const MultiFactorAuthState({
    this.status = MultiFactorAuthStatus.initial,
    this.completedFactors = const {},
    this.requiredFactors = const {},
    this.biometricAvailable = false,
    this.totpConfigured = false,
    this.locationRequired = false,
    this.errorMessage,
    this.currentSecurityProfile,
  });

  bool get isCompleted => completedFactors.containsAll(requiredFactors);

  MultiFactorAuthState copyWith({
    MultiFactorAuthStatus? status,
    Set<String>? completedFactors,
    Set<String>? requiredFactors,
    bool? biometricAvailable,
    bool? totpConfigured,
    bool? locationRequired,
    String? errorMessage,
    String? currentSecurityProfile,
  }) {
    return MultiFactorAuthState(
      status: status ?? this.status,
      completedFactors: completedFactors ?? this.completedFactors,
      requiredFactors: requiredFactors ?? this.requiredFactors,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      totpConfigured: totpConfigured ?? this.totpConfigured,
      locationRequired: locationRequired ?? this.locationRequired,
      errorMessage: errorMessage,
      currentSecurityProfile:
          currentSecurityProfile ?? this.currentSecurityProfile,
    );
  }

  @override
  List<Object?> get props => [
        status,
        completedFactors,
        requiredFactors,
        biometricAvailable,
        totpConfigured,
        locationRequired,
        errorMessage,
        currentSecurityProfile,
      ];
}
