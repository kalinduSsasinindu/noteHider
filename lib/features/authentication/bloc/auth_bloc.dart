import 'package:bloc/bloc.dart';
import 'package:notehider/features/authentication/bloc/auth_event.dart';
import 'package:notehider/features/authentication/bloc/auth_state.dart';
import 'package:notehider/services/crypto_service.dart';
import 'package:notehider/services/storage_service.dart';

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
  }

  Future<void> _onCheckFirstTimeSetup(
    CheckFirstTimeSetup event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isPasswordSet = await _storageService.isPasswordSet();

      if (isPasswordSet) {
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
        errorMessage: 'Failed to check setup status',
      ));
    }
  }

  Future<void> _onSetupPassword(
    SetupPassword event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Generate salt and hash password with Argon2
      final salt = _cryptoService.generateSalt();
      final hashedPassword = await _cryptoService.hashPassword(
        event.password,
        salt,
      );

      // Store the hashed password and salt securely
      await _storageService.storePasswordHash(hashedPassword);
      await _storageService.storeSalt(salt);
      await _storageService.setPasswordSetFlag(true);

      // Generate master key for file encryption
      final masterKey = await _cryptoService.deriveMasterKey(
        event.password,
        salt,
      );
      await _storageService.storeMasterKey(masterKey);

      emit(state.copyWith(
        status: AuthStatus.unlocked,
        isPasswordSet: true,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to setup password: ${e.toString()}',
      ));
    }
  }

  Future<void> _onVerifyPassword(
    VerifyPassword event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final storedHash = await _storageService.getPasswordHash();
      final salt = await _storageService.getSalt();

      if (storedHash == null || salt == null) {
        emit(state.copyWith(
          status: AuthStatus.locked,
          errorMessage: 'Authentication data not found',
        ));
        return;
      }

      final isValid = await _cryptoService.verifyPassword(
        event.password,
        storedHash,
        salt,
      );

      if (isValid) {
        // Regenerate master key for this session
        final masterKey = await _cryptoService.deriveMasterKey(
          event.password,
          salt,
        );
        await _storageService.storeMasterKey(masterKey);

        emit(state.copyWith(
          status: AuthStatus.unlocked,
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
        status: AuthStatus.locked,
        errorMessage: 'Authentication failed: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLockApp(
    LockApp event,
    Emitter<AuthState> emit,
  ) async {
    // Clear sensitive data from memory
    await _storageService.clearSessionData();

    emit(state.copyWith(
      status: AuthStatus.locked,
      errorMessage: null,
    ));
  }

  Future<void> _onResetApp(
    ResetApp event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _storageService.clearAllData();

      emit(const AuthState.initial());
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to reset app: ${e.toString()}',
      ));
    }
  }
}
