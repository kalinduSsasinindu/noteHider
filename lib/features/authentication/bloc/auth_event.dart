import 'package:equatable/equatable.dart';

/// 🔐 CORE AUTHENTICATION EVENTS
///
/// Simplified events for core authentication only:
/// • Password setup and verification
/// • App locking/unlocking
/// • Authentication state management
///
/// Security events moved to SecurityBloc
/// Multi-factor auth events moved to MultiFactorAuthBloc
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
