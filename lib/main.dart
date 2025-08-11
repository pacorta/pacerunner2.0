import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled/auth_wraper.dart';
import 'root_shell.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase/firebase_options.dart';

//import 'home_screen.dart';

void main() async {
  try {
    print('Starting app initialization...');

    WidgetsFlutterBinding.ensureInitialized();
    print('Flutter binding initialized');

    await dotenv.load(fileName: ".env");
    print('Environment variables loaded');

    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      print('Initializing Firebase...');
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('Firebase initialized successfully');
      } catch (firebaseError) {
        if (firebaseError.toString().contains('duplicate-app')) {
          print('Firebase was already initialized, continuing...');
        } else {
          // If it's a different Firebase error, rethrow it
          rethrow;
        }
      }
    } else {
      print('Firebase was already initialized, using existing instance');
    }

    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    print('App started successfully');
  } catch (e, stackTrace) {
    print('Error during initialization: $e');
    print('Stack trace: $stackTrace');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The PACERUNNER',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 255, 255, 255)),
        useMaterial3: true,
      ),
      // Wrap auth with RootShell so bottom nav is persistent across tabs
      home: const AuthWrapper(),
    );
  }
}
