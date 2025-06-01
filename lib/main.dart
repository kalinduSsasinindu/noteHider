import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:notehider/bloc_observer.dart';
import 'package:notehider/features/authentication/bloc/auth_event.dart';
import 'package:notehider/features/authentication/bloc/auth_bloc.dart';
import 'package:notehider/features/authentication/bloc/auth_state.dart';
import 'package:notehider/homepage.dart';
import 'package:notehider/bloc/tab_bloc.dart';
import 'package:notehider/features/notes/bloc/notes_bloc.dart';
import 'package:notehider/services/crypto_service.dart';
import 'package:notehider/services/storage_service.dart';
import 'package:notehider/services/security_config_service.dart';
import 'package:notehider/services/biometric_service.dart';
import 'package:notehider/services/location_service.dart';
import 'package:notehider/services/totp_service.dart';

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
  final biometricService = BiometricService();
  final locationService = LocationService();
  final totpService = TOTPService();

  // Initialize services
  await storageService.initialize();
  await securityConfigService.initialize();
  await biometricService.initialize();
  await locationService.initialize();
  await totpService.initialize();

  runApp(MyApp(
    cryptoService: cryptoService,
    storageService: storageService,
    securityConfigService: securityConfigService,
    biometricService: biometricService,
    locationService: locationService,
    totpService: totpService,
  ));
}

class MyApp extends StatelessWidget {
  final CryptoService cryptoService;
  final StorageService storageService;
  final SecurityConfigService securityConfigService;
  final BiometricService biometricService;
  final LocationService locationService;
  final TOTPService totpService;

  const MyApp({
    super.key,
    required this.cryptoService,
    required this.storageService,
    required this.securityConfigService,
    required this.biometricService,
    required this.locationService,
    required this.totpService,
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
