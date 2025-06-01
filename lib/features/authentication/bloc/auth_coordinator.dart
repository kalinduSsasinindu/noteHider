import 'package:bloc/bloc.dart';
import 'package:notehider/features/authentication/bloc/auth_bloc.dart';
import 'package:notehider/features/authentication/bloc/auth_state.dart';
import 'package:notehider/features/authentication/bloc/auth_event.dart';
import 'package:notehider/features/authentication/bloc/multi_factor_auth_bloc.dart';
import 'package:notehider/features/authentication/bloc/multi_factor_auth_state.dart';
import 'package:notehider/features/authentication/bloc/multi_factor_auth_event.dart';
import 'package:notehider/services/storage_service.dart';

/// 🎯 AUTHENTICATION COORDINATOR
///
/// Manages the flow between basic password authentication and multi-factor authentication
///
/// Flow:
/// 1. User enters password → AuthBloc
/// 2. If password valid → Check if additional factors are configured
/// 3. If additional factors exist → Trigger MultiFactorAuthBloc
/// 4. When all factors complete → Grant full access
class AuthCoordinator extends Bloc<AuthCoordinatorEvent, AuthCoordinatorState> {
  final AuthBloc _authBloc;
  final MultiFactorAuthBloc _multiFactorAuthBloc;
  final StorageService _storageService;

  AuthCoordinator({
    required AuthBloc authBloc,
    required MultiFactorAuthBloc multiFactorAuthBloc,
    required StorageService storageService,
  })  : _authBloc = authBloc,
        _multiFactorAuthBloc = multiFactorAuthBloc,
        _storageService = storageService,
        super(const AuthCoordinatorState.initial()) {
    on<StartAuthentication>(_onStartAuthentication);
    on<PasswordAuthCompleted>(_onPasswordAuthCompleted);
    on<MultiFactorAuthCompleted>(_onMultiFactorAuthCompleted);
    on<SkipMultiFactorAuth>(_onSkipMultiFactorAuth);
    on<EnableAdditionalSecurity>(_onEnableAdditionalSecurity);
    on<LockApplication>(_onLockApplication);

    // Listen to AuthBloc state changes
    _authBloc.stream.listen((authState) {
      if (authState.status == AuthStatus.authenticated) {
        add(const PasswordAuthCompleted());
      }
    });

    // Listen to MultiFactorAuthBloc state changes
    _multiFactorAuthBloc.stream.listen((mfaState) {
      if (mfaState.status == MultiFactorAuthStatus.completed) {
        add(const MultiFactorAuthCompleted());
      }
    });
  }

  Future<void> _onStartAuthentication(
    StartAuthentication event,
    Emitter<AuthCoordinatorState> emit,
  ) async {
    emit(state.copyWith(status: AuthCoordinatorStatus.authenticating));

    // Delegate to AuthBloc for password authentication
    _authBloc.add(VerifyPassword(event.password));
  }

  Future<void> _onPasswordAuthCompleted(
    PasswordAuthCompleted event,
    Emitter<AuthCoordinatorState> emit,
  ) async {
    try {
      // Check if user has additional security factors configured
      final hasAdditionalFactors = await _checkAdditionalFactorsConfigured();

      if (hasAdditionalFactors) {
        // User has additional factors - trigger multi-factor auth
        emit(state.copyWith(
          status: AuthCoordinatorStatus.multiFactorRequired,
          passwordCompleted: true,
        ));

        // Get user's security profile
        final securityProfile = await _getUserSecurityProfile();

        // Trigger multi-factor authentication
        _multiFactorAuthBloc.add(InitializeMultiFactorAuth(
          securityProfile: securityProfile,
          configuration: {}, // Empty configuration for now
        ));
      } else {
        // No additional factors - grant full access
        emit(state.copyWith(
          status: AuthCoordinatorStatus.fullyAuthenticated,
          passwordCompleted: true,
          multiFactorCompleted: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthCoordinatorStatus.failed,
        errorMessage: 'Authentication coordination failed: $e',
      ));
    }
  }

  Future<void> _onMultiFactorAuthCompleted(
    MultiFactorAuthCompleted event,
    Emitter<AuthCoordinatorState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthCoordinatorStatus.fullyAuthenticated,
      multiFactorCompleted: true,
    ));
  }

  Future<void> _onSkipMultiFactorAuth(
    SkipMultiFactorAuth event,
    Emitter<AuthCoordinatorState> emit,
  ) async {
    // Allow user to skip if they haven't set up additional factors yet
    if (!state.hasRequiredAdditionalFactors) {
      emit(state.copyWith(
        status: AuthCoordinatorStatus.fullyAuthenticated,
        multiFactorCompleted: true,
      ));
    }
  }

  Future<void> _onEnableAdditionalSecurity(
    EnableAdditionalSecurity event,
    Emitter<AuthCoordinatorState> emit,
  ) async {
    try {
      // Save the security profile preference
      await _storageService.storeSecurityProfile(event.securityProfile);

      emit(state.copyWith(
        status: AuthCoordinatorStatus.configuringAdditionalSecurity,
        currentSecurityProfile: event.securityProfile,
      ));

      // Initialize multi-factor auth for configuration
      _multiFactorAuthBloc.add(InitializeMultiFactorAuth(
        securityProfile: event.securityProfile,
        configuration: {}, // Empty configuration for now
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthCoordinatorStatus.failed,
        errorMessage: 'Failed to enable additional security: $e',
      ));
    }
  }

  Future<void> _onLockApplication(
    LockApplication event,
    Emitter<AuthCoordinatorState> emit,
  ) async {
    // Reset all authentication state
    emit(const AuthCoordinatorState.initial());

    // Lock the underlying auth blocs
    _authBloc.add(const LockApp());
    _multiFactorAuthBloc.add(const ResetAuthFactors());
  }

  // Helper methods
  Future<bool> _checkAdditionalFactorsConfigured() async {
    try {
      final profile = await _storageService.getSecurityProfile();
      return profile != null && profile != 'basic';
    } catch (e) {
      return false;
    }
  }

  Future<String> _getUserSecurityProfile() async {
    try {
      return await _storageService.getSecurityProfile() ?? 'basic';
    } catch (e) {
      return 'basic';
    }
  }
}

// Events
abstract class AuthCoordinatorEvent {
  const AuthCoordinatorEvent();
}

class StartAuthentication extends AuthCoordinatorEvent {
  final String password;
  const StartAuthentication(this.password);
}

class PasswordAuthCompleted extends AuthCoordinatorEvent {
  const PasswordAuthCompleted();
}

class MultiFactorAuthCompleted extends AuthCoordinatorEvent {
  const MultiFactorAuthCompleted();
}

class SkipMultiFactorAuth extends AuthCoordinatorEvent {
  const SkipMultiFactorAuth();
}

class EnableAdditionalSecurity extends AuthCoordinatorEvent {
  final String
      securityProfile; // 'basic', 'professional', 'military', 'paranoid'
  const EnableAdditionalSecurity(this.securityProfile);
}

class LockApplication extends AuthCoordinatorEvent {
  const LockApplication();
}

// States
enum AuthCoordinatorStatus {
  initial,
  authenticating,
  multiFactorRequired,
  configuringAdditionalSecurity,
  fullyAuthenticated,
  failed,
}

class AuthCoordinatorState {
  final AuthCoordinatorStatus status;
  final bool passwordCompleted;
  final bool multiFactorCompleted;
  final bool hasRequiredAdditionalFactors;
  final String? currentSecurityProfile;
  final String? errorMessage;

  const AuthCoordinatorState({
    this.status = AuthCoordinatorStatus.initial,
    this.passwordCompleted = false,
    this.multiFactorCompleted = false,
    this.hasRequiredAdditionalFactors = false,
    this.currentSecurityProfile,
    this.errorMessage,
  });

  const AuthCoordinatorState.initial() : this();

  AuthCoordinatorState copyWith({
    AuthCoordinatorStatus? status,
    bool? passwordCompleted,
    bool? multiFactorCompleted,
    bool? hasRequiredAdditionalFactors,
    String? currentSecurityProfile,
    String? errorMessage,
  }) {
    return AuthCoordinatorState(
      status: status ?? this.status,
      passwordCompleted: passwordCompleted ?? this.passwordCompleted,
      multiFactorCompleted: multiFactorCompleted ?? this.multiFactorCompleted,
      hasRequiredAdditionalFactors:
          hasRequiredAdditionalFactors ?? this.hasRequiredAdditionalFactors,
      currentSecurityProfile:
          currentSecurityProfile ?? this.currentSecurityProfile,
      errorMessage: errorMessage,
    );
  }

  bool get isFullyAuthenticated =>
      passwordCompleted &&
      (multiFactorCompleted || !hasRequiredAdditionalFactors);

  bool get canAccessSecureArea =>
      status == AuthCoordinatorStatus.fullyAuthenticated;
}
