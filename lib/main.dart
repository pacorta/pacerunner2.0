import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled/auth_wraper.dart';

//import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyBv36Hi6ONcFmKpAGJDYYQpLk9nlD-Eus8",
          authDomain:
              "pacerunner-backend.firebaseapp.com", //YOUR_PROJECT_ID.firebaseapp.com
          projectId: "pacerunner-backend",
          storageBucket: "pacerunner-backend.appspot.com",
          messagingSenderId: "1051561767754", //GCM_SENDER_ID
          appId: "1:1051561767754:ios:62d6231d0315b5514307b3"),
    );
  }
  runApp(
    //(1)ProviderScope wraps the entire app, providing a container for all providers defined in the app.
    //It's crucial because it initializes the provider system and allows the state managed by providers to be shared across the widget tree.
    const ProviderScope(
      child: MyApp(),
    ),
  );
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
      home: const AuthWrapper(),
    );
  }
}
