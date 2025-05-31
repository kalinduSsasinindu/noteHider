import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notehider/bloc_observer.dart';
import 'package:notehider/homepage.dart';
import 'package:notehider/bloc/tab_bloc.dart';

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
    return MaterialApp(
      title: 'NoteHider',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: const Color(0xFFFFA726),
        scaffoldBackgroundColor: Colors.grey[50],
        useMaterial3: false,
      ),
      home: BlocProvider(
        create: (context) => TabBloc(),
        child: const NotesHomePage(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
