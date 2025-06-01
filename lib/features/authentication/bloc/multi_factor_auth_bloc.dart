import 'package:bloc/bloc.dart';
import 'package:notehider/services/biometric_service.dart';
import 'package:notehider/services/location_service.dart';
import 'package:notehider/services/totp_service.dart';
import 'package:notehider/features/authentication/bloc/multi_factor_auth_event.dart';
import 'package:notehider/features/authentication/bloc/multi_factor_auth_state.dart';

class MultiFactorAuthBloc
    extends Bloc<MultiFactorAuthEvent, MultiFactorAuthState> {
  final BiometricService _biometricService;
  final LocationService _locationService;
  final TOTPService _totpService;

  MultiFactorAuthBloc({
    required BiometricService biometricService,
    required LocationService locationService,
    required TOTPService totpService,
  })  : _biometricService = biometricService,
        _locationService = locationService,
        _totpService = totpService,
        super(const MultiFactorAuthState()) {
    on<InitializeMultiFactorAuth>(_onInitializeMultiFactorAuth);
    on<RequestBiometricAuth>(_onRequestBiometricAuth);
    on<VerifyTOTPCode>(_onVerifyTOTPCode);
    on<VerifyLocationSecurity>(_onVerifyLocationSecurity);
    on<ResetAuthFactors>(_onResetAuthFactors);
    on<CompleteBiometricAuth>(_onCompleteBiometricAuth);
    on<CompleteTOTPAuth>(_onCompleteTOTPAuth);
    on<CompleteLocationAuth>(_onCompleteLocationAuth);
  }

  Future<void> _onInitializeMultiFactorAuth(
    InitializeMultiFactorAuth event,
    Emitter<MultiFactorAuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MultiFactorAuthStatus.configuring));

      // For now, use simplified availability checks
      final biometricAvailable = true; // Placeholder
      final totpConfigured = false; // Placeholder

      // Determine required factors based on security profile
      final requiredFactors = _determineRequiredFactors(
        event.securityProfile,
        biometricAvailable,
        totpConfigured,
      );

      emit(state.copyWith(
        status: MultiFactorAuthStatus.awaitingFactors,
        requiredFactors: requiredFactors,
        biometricAvailable: biometricAvailable,
        totpConfigured: totpConfigured,
        locationRequired: requiredFactors.contains('location'),
        currentSecurityProfile: event.securityProfile,
        completedFactors: {},
      ));

      // Auto-trigger required factors
      if (requiredFactors.contains('biometric') && biometricAvailable) {
        add(const RequestBiometricAuth());
      } else if (requiredFactors.contains('totp') && totpConfigured) {
        emit(state.copyWith(status: MultiFactorAuthStatus.totpRequired));
      } else if (requiredFactors.contains('location')) {
        add(const VerifyLocationSecurity());
      }
    } catch (e) {
      emit(state.copyWith(
        status: MultiFactorAuthStatus.failed,
        errorMessage: 'Multi-factor auth initialization failed: $e',
      ));
    }
  }

  Future<void> _onRequestBiometricAuth(
    RequestBiometricAuth event,
    Emitter<MultiFactorAuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MultiFactorAuthStatus.biometricRequired));

      // Simulate biometric authentication
      // In real implementation, this would call the actual biometric service
      final biometricResult = true; // Placeholder

      add(CompleteBiometricAuth(biometricResult));
    } catch (e) {
      emit(state.copyWith(
        status: MultiFactorAuthStatus.failed,
        errorMessage: 'Biometric authentication error: $e',
      ));
    }
  }

  Future<void> _onVerifyTOTPCode(
    VerifyTOTPCode event,
    Emitter<MultiFactorAuthState> emit,
  ) async {
    try {
      // Simulate TOTP verification
      // In real implementation, this would call the actual TOTP service
      final isValid = event.code.length == 6; // Placeholder validation

      add(CompleteTOTPAuth(isValid));
    } catch (e) {
      emit(state.copyWith(
        status: MultiFactorAuthStatus.failed,
        errorMessage: 'TOTP verification error: $e',
      ));
    }
  }

  Future<void> _onVerifyLocationSecurity(
    VerifyLocationSecurity event,
    Emitter<MultiFactorAuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MultiFactorAuthStatus.locationRequired));

      // Simulate location verification
      // In real implementation, this would call the actual location service
      final locationValid = true; // Placeholder

      add(CompleteLocationAuth(locationValid));
    } catch (e) {
      emit(state.copyWith(
        status: MultiFactorAuthStatus.failed,
        errorMessage: 'Location verification error: $e',
      ));
    }
  }

  Future<void> _onCompleteBiometricAuth(
    CompleteBiometricAuth event,
    Emitter<MultiFactorAuthState> emit,
  ) async {
    if (event.success) {
      final updatedFactors = Set<String>.from(state.completedFactors)
        ..add('biometric');

      emit(state.copyWith(
        completedFactors: updatedFactors,
        status: _getNextStatus(updatedFactors),
      ));

      _checkCompletion(emit);
    } else {
      emit(state.copyWith(
        status: MultiFactorAuthStatus.failed,
        errorMessage: 'Biometric authentication failed',
      ));
    }
  }

  Future<void> _onCompleteTOTPAuth(
    CompleteTOTPAuth event,
    Emitter<MultiFactorAuthState> emit,
  ) async {
    if (event.success) {
      final updatedFactors = Set<String>.from(state.completedFactors)
        ..add('totp');

      emit(state.copyWith(
        completedFactors: updatedFactors,
        status: _getNextStatus(updatedFactors),
      ));

      _checkCompletion(emit);
    } else {
      emit(state.copyWith(
        status: MultiFactorAuthStatus.failed,
        errorMessage: 'Invalid TOTP code',
      ));
    }
  }

  Future<void> _onCompleteLocationAuth(
    CompleteLocationAuth event,
    Emitter<MultiFactorAuthState> emit,
  ) async {
    if (event.success) {
      final updatedFactors = Set<String>.from(state.completedFactors)
        ..add('location');

      emit(state.copyWith(
        completedFactors: updatedFactors,
        status: _getNextStatus(updatedFactors),
      ));

      _checkCompletion(emit);
    } else {
      emit(state.copyWith(
        status: MultiFactorAuthStatus.failed,
        errorMessage: 'Location verification failed',
      ));
    }
  }

  Future<void> _onResetAuthFactors(
    ResetAuthFactors event,
    Emitter<MultiFactorAuthState> emit,
  ) async {
    emit(state.copyWith(
      status: MultiFactorAuthStatus.initial,
      completedFactors: {},
      errorMessage: null,
    ));
  }

  Set<String> _determineRequiredFactors(
    String securityProfile,
    bool biometricAvailable,
    bool totpConfigured,
  ) {
    final factors = <String>{};

    switch (securityProfile.toLowerCase()) {
      case 'basic':
        // Basic profile - optional biometric if available
        if (biometricAvailable) factors.add('biometric');
        break;

      case 'professional':
        // Professional profile - biometric + TOTP if configured
        if (biometricAvailable) factors.add('biometric');
        if (totpConfigured) factors.add('totp');
        break;

      case 'military':
        // Military profile - all available factors required
        if (biometricAvailable) factors.add('biometric');
        if (totpConfigured) factors.add('totp');
        factors.add('location');
        break;

      case 'paranoid':
        // Paranoid profile - everything required
        factors.addAll(['biometric', 'totp', 'location']);
        break;

      default:
        // Default to basic
        if (biometricAvailable) factors.add('biometric');
        break;
    }

    return factors;
  }

  MultiFactorAuthStatus _getNextStatus(Set<String> completedFactors) {
    final remainingFactors = state.requiredFactors.difference(completedFactors);

    if (remainingFactors.isEmpty) {
      return MultiFactorAuthStatus.completed;
    }

    if (remainingFactors.contains('biometric')) {
      return MultiFactorAuthStatus.biometricRequired;
    } else if (remainingFactors.contains('totp')) {
      return MultiFactorAuthStatus.totpRequired;
    } else if (remainingFactors.contains('location')) {
      return MultiFactorAuthStatus.locationRequired;
    }

    return MultiFactorAuthStatus.awaitingFactors;
  }

  void _checkCompletion(Emitter<MultiFactorAuthState> emit) {
    if (state.isCompleted) {
      emit(state.copyWith(status: MultiFactorAuthStatus.completed));
    }
  }
}
