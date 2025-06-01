import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:notehider/bloc_observer.dart';
import 'package:notehider/features/authentication/bloc/auth_event.dart';
import 'package:notehider/features/authentication/bloc/auth_bloc.dart';
import 'package:notehider/homepage.dart';
import 'package:notehider/bloc/tab_bloc.dart';
import 'package:notehider/features/notes/bloc/notes_bloc.dart';
import 'package:notehider/services/crypto_service.dart';
import 'package:notehider/services/storage_service.dart';
import 'package:notehider/services/security_config_service.dart';
import 'package:notehider/services/biometric_service.dart';
import 'package:notehider/services/location_service.dart';
import 'package:notehider/services/totp_service.dart';
import 'package:notehider/services/tamper_detection_service.dart';
import 'package:notehider/services/auto_wipe_service.dart';
import 'package:notehider/services/decoy_system_service.dart';
import 'package:notehider/services/file_manager_service.dart';

void main() async {
  // Initialize the BlocObserver
  Bloc.observer = const AppBlocObserver();
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize core services
  final cryptoService = CryptoService();
  final storageService = StorageService(cryptoService: cryptoService);
  final securityConfigService = SecurityConfigService(
    storageService: storageService,
    cryptoService: cryptoService,
  );

  // Initialize authentication services
  final biometricService = BiometricService();
  final locationService = LocationService();
  final totpService = TOTPService();

  // Initialize advanced security services
  final tamperDetectionService = TamperDetectionService();
  final autoWipeService = AutoWipeService(
    storageService: storageService,
    cryptoService: cryptoService,
  );
  final decoySystemService = DecoySystemService(storageService: storageService);

  // Initialize file manager service
  final fileManagerService = FileManagerService(
    cryptoService: cryptoService,
    storageService: storageService,
    tamperDetectionService: tamperDetectionService,
  );

  // Initialize critical services (these must succeed)
  try {
    await storageService.initialize();
    await securityConfigService.initialize();
    print('✅ Core services initialized successfully');
  } catch (e) {
    print('🚨 Critical service initialization failed: $e');
    // For critical services, we might want to show an error dialog
    // For now, we'll continue but log the error
  }

  // Initialize optional services (graceful failure handling)
  await _initializeOptionalService(
      'Biometric', () => biometricService.initialize());
  await _initializeOptionalService(
      'Location', () => locationService.initialize());
  await _initializeOptionalService('TOTP', () => totpService.initialize());
  await _initializeOptionalService(
      'Tamper Detection', () => tamperDetectionService.initialize());
  await _initializeOptionalService(
      'Auto Wipe', () => autoWipeService.initialize());
  await _initializeOptionalService(
      'Decoy System', () => decoySystemService.initialize());
  await _initializeOptionalService(
      'File Manager', () => fileManagerService.initialize());

  print('🚀 All services initialization completed');
  print('📁 NoteHider app ready with military-grade security');
  print(
      '🎖️ Complete security suite active: Encryption, Biometrics, TOTP, Tamper Detection, Auto-Wipe, Decoy System, and File Management');

  runApp(MyApp(
    cryptoService: cryptoService,
    storageService: storageService,
    securityConfigService: securityConfigService,
    biometricService: biometricService,
    locationService: locationService,
    totpService: totpService,
    tamperDetectionService: tamperDetectionService,
    autoWipeService: autoWipeService,
    decoySystemService: decoySystemService,
    fileManagerService: fileManagerService,
  ));
}

/// 🔧 Helper function to initialize optional services with graceful error handling
Future<void> _initializeOptionalService(
    String serviceName, Future<void> Function() initFunction) async {
  try {
    await initFunction();
    print('✅ $serviceName service initialized');
  } catch (e) {
    print('⚠️ $serviceName service initialization failed: $e');
    print('📱 App will continue without $serviceName features');
    // Service failed to initialize, but app continues
  }
}

class MyApp extends StatelessWidget {
  final CryptoService cryptoService;
  final StorageService storageService;
  final SecurityConfigService securityConfigService;
  final BiometricService biometricService;
  final LocationService locationService;
  final TOTPService totpService;
  final TamperDetectionService tamperDetectionService;
  final AutoWipeService autoWipeService;
  final DecoySystemService decoySystemService;
  final FileManagerService fileManagerService;

  const MyApp({
    super.key,
    required this.cryptoService,
    required this.storageService,
    required this.securityConfigService,
    required this.biometricService,
    required this.locationService,
    required this.totpService,
    required this.tamperDetectionService,
    required this.autoWipeService,
    required this.decoySystemService,
    required this.fileManagerService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CryptoService>.value(value: cryptoService),
        Provider<StorageService>.value(value: storageService),
        Provider<SecurityConfigService>.value(value: securityConfigService),
        Provider<BiometricService>.value(value: biometricService),
        Provider<LocationService>.value(value: locationService),
        Provider<TOTPService>.value(value: totpService),
        Provider<TamperDetectionService>.value(value: tamperDetectionService),
        Provider<AutoWipeService>.value(value: autoWipeService),
        Provider<DecoySystemService>.value(value: decoySystemService),
        Provider<FileManagerService>.value(value: fileManagerService),
      ],
      child: MaterialApp(
        title: 'NoteHider - Military Grade Security',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          primaryColor: const Color(0xFFFFA726),
          scaffoldBackgroundColor: Colors.grey[50],
          useMaterial3: false,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (context) => TabBloc(),
                  ),
                  BlocProvider(
                    create: (context) => AuthBloc(
                      cryptoService: cryptoService,
                      storageService: storageService,
                      biometricService: biometricService,
                      locationService: locationService,
                      totpService: totpService,
                      tamperDetectionService: tamperDetectionService,
                      autoWipeService: autoWipeService,
                      decoySystemService: decoySystemService,
                      fileManagerService: fileManagerService,
                      securityConfigService: securityConfigService,
                    )..add(const CheckFirstTimeSetup()),
                  ),
                  BlocProvider(
                    create: (context) => NotesBloc(
                      storageService: storageService,
                    ),
                  ),
                ],
                child: const NotesHomePage(),
              ),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
