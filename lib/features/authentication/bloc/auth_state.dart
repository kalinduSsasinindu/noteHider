import 'package:equatable/equatable.dart';

/// 🔐 CORE AUTHENTICATION STATE
///
/// Simplified state for core authentication only:
/// • Password setup status
/// • Authentication status
/// • Error handling
///
/// Security state moved to SecurityBloc
/// Multi-factor auth state moved to MultiFactorAuthBloc
enum AuthStatus {
  initial,
  firstTimeSetup,
  locked,
  authenticated,
  loading,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final bool isPasswordSet;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.isPasswordSet = false,
    this.errorMessage,
  });

  const AuthState.initial() : this();

  AuthState copyWith({
    AuthStatus? status,
    bool? isPasswordSet,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      isPasswordSet: isPasswordSet ?? this.isPasswordSet,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, isPasswordSet, errorMessage];
}
