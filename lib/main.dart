import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:notehider/bloc_observer.dart';
import 'package:notehider/features/authentication/bloc/auth_event.dart';
import 'package:notehider/homepage.dart';
import 'package:notehider/bloc/tab_bloc.dart';
import 'package:notehider/features/authentication/bloc/auth_bloc.dart';
import 'package:notehider/features/notes/bloc/notes_bloc.dart';
import 'package:notehider/services/crypto_service.dart';
import 'package:notehider/services/storage_service.dart';

void main() {
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide services at the app level
        Provider<CryptoService>(
          create: (_) => CryptoService(),
        ),
        Provider<StorageService>(
          create: (context) => StorageService(
            cryptoService: context.read<CryptoService>(),
          ),
        ),
      ],
      child: Consumer2<CryptoService, StorageService>(
        builder: (context, cryptoService, storageService, child) {
          return MaterialApp(
            title: 'NoteHider',
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
          );
        },
      ),
    );
  }
}
