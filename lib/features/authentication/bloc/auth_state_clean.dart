import 'package:equatable/equatable.dart';

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
