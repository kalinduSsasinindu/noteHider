import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:notehider/services/crypto_service.dart';
import 'package:notehider/services/storage_service.dart';

// EVENTS
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

// STATES
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

// BLOC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CryptoService _cryptoService;
  final StorageService _storageService;

  AuthBloc({
    required CryptoService cryptoService,
    required StorageService storageService,
  })  : _cryptoService = cryptoService,
        _storageService = storageService,
        super(const AuthState.initial()) {
    on<CheckFirstTimeSetup>(_onCheckFirstTimeSetup);
    on<SetupPassword>(_onSetupPassword);
    on<VerifyPassword>(_onVerifyPassword);
    on<LockApp>(_onLockApp);
    on<ResetApp>(_onResetApp);
    on<ClearAuthData>(_onClearAuthData);
  }

  Future<void> _onCheckFirstTimeSetup(
    CheckFirstTimeSetup event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));

      await _storageService.initialize();
      final hasPassword = await _storageService.hasStoredPassword();

      if (hasPassword) {
        emit(state.copyWith(
          status: AuthStatus.locked,
          isPasswordSet: true,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.firstTimeSetup,
          isPasswordSet: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Setup check failed: $e',
      ));
    }
  }

  Future<void> _onSetupPassword(
    SetupPassword event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));

      // Use the existing setupPassword method from StorageService
      await _storageService.setupPassword(event.password);

      // Get the master key that was generated during setup
      final masterKey = await _storageService.getMasterKey();
      if (masterKey != null) {
        _cryptoService.setMasterKey(masterKey);
      }

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        isPasswordSet: true,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Password setup failed: $e',
      ));
    }
  }

  Future<void> _onVerifyPassword(
    VerifyPassword event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));

      // Use the existing verifyPassword method from StorageService
      final isValid = await _storageService.verifyPassword(event.password);

      if (isValid) {
        // Get the master key for decryption
        final masterKey = await _storageService.getMasterKey();
        if (masterKey != null) {
          _cryptoService.setMasterKey(masterKey);
        }

        emit(state.copyWith(
          status: AuthStatus.authenticated,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.locked,
          errorMessage: 'Invalid password',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Password verification failed: $e',
      ));
    }
  }

  Future<void> _onLockApp(
    LockApp event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Clear the master key from memory for security
      // We'll use a simple approach since clearMasterKey doesn't exist
      // The setMasterKey with null or empty bytes should clear it
      _cryptoService.setMasterKey(Uint8List(0));

      emit(state.copyWith(
        status: AuthStatus.locked,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Lock operation failed: $e',
      ));
    }
  }

  Future<void> _onResetApp(
    ResetApp event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));

      // Clear all stored data
      await _storageService.clearAllData();

      // Clear crypto keys
      _cryptoService.setMasterKey(Uint8List(0));

      emit(const AuthState.initial());
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Reset failed: $e',
      ));
    }
  }

  Future<void> _onClearAuthData(
    ClearAuthData event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));

      // Clear authentication data
      await _storageService.clearAllData();
      _cryptoService.setMasterKey(Uint8List(0));

      emit(const AuthState.initial());
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to clear authentication data: $e',
      ));
    }
  }
}
