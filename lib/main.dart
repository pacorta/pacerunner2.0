import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:untitled/widgets/progress_bar.dart';
import 'package:untitled/widgets/unit_preference_provider.dart';
import 'widgets/map.dart';
import 'widgets/current_run.dart';
import 'widgets/tracking_provider.dart';
import 'widgets/distance_provider.dart';
import 'widgets/pace_bar.dart';

import 'firebase/firebaseWidgets/login_page.dart';
import 'firebase/firebaseWidgets/running_stats.dart';
import 'firebase/firebase_options.dart';

//import 'firebase/back-end-main.dart';

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
      home: const MyHomePage(title: 'The Pacerunner Home Screen'),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      //This stream listens for changes in the user's authentication state,
      //allowing the app to switch between the login page and the main running stats page.
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return RunningStatsPage();
        } else {
          return LoginPage();
        }
      },
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final isTracking = ref.watch(trackingProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/pacerunner6.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              ElevatedButton(
                  child: const Text('Click to Start Running'),
                  onPressed: () {
                    final trackingNotifier = ref.read(trackingProvider
                        .notifier); //Use ref.read(provider) when you want to read a value without rebuilding the widget.
                    if (isTracking) {
                      trackingNotifier.state = false;
                      print(
                          'Traveled distance: ${ref.read(distanceProvider).toStringAsFixed(2)} km');
                    } else {
                      trackingNotifier.state = true;
                      ref.read(distanceProvider.notifier).state =
                          0.0; //Use ref.read(provider) when you want to read a value without rebuilding the widget.
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CurrentRun()),
                    );
                  }),
              ElevatedButton(
                  child: const Text('Back End Demo'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    );
                  }),
              const SizedBox(height: 100),
              //#km2miles
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      child: Text('km/mi'),
                    ),
                    Switch(
                      value:
                          ref.watch(distanceUnitProvider) == DistanceUnit.miles,
                      onChanged: (value) {
                        ref.read(distanceUnitProvider.notifier).state = value
                            ? DistanceUnit.miles
                            : DistanceUnit.kilometers;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
