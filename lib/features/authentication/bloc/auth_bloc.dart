import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:notehider/features/authentication/bloc/auth_event.dart';
import 'package:notehider/features/authentication/bloc/auth_state.dart';
import 'package:notehider/services/crypto_service.dart';
import 'package:notehider/services/storage_service.dart';

/// 🔐 CORE AUTHENTICATION BLOC
///
/// Simplified authentication bloc that handles only core authentication:
/// • Password setup and verification
/// • App locking/unlocking
/// • Authentication state management
///
/// Security operations have been moved to SecurityBloc
/// Multi-factor authentication has been moved to MultiFactorAuthBloc
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
    if (state.status == AuthStatus.loading ||
        state.status == AuthStatus.authenticated) {
      // Ignore duplicate requests while already processing or done.
      return;
    }
    try {
      emit(state.copyWith(status: AuthStatus.loading));

      // Use device-binding password setup for stronger security
      await _storageService.setupPasswordWithDeviceBinding(event.password);

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

      // Verify with device-binding (password tied to device DNA)
      final isValid =
          await _storageService.verifyPasswordWithDeviceBinding(event.password);

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
