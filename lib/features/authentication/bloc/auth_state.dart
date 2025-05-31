import 'package:equatable/equatable.dart';






enum AuthStatus {
  firstTimeSetup, // No password set yet
  locked, // Password set, but user needs to authenticate
  unlocked, // User authenticated, can access hidden area
  normalMode, // User in regular notes mode
}

class AuthState extends Equatable {
  final AuthStatus status;
  final bool isPasswordSet;
  final String? errorMessage;

  const AuthState({
    required this.status,
    required this.isPasswordSet,
    this.errorMessage,
  });

  const AuthState.initial()
      : status = AuthStatus.firstTimeSetup,
        isPasswordSet = false,
        errorMessage = null;

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
