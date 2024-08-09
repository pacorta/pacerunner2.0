import 'package:flutter/material.dart';
import 'package:untitled/widgets/progress_bar.dart';

import 'widgets/map.dart';
import 'widgets/current_run.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/tracking_provider.dart';
import 'widgets/distance_provider.dart';

void gmaps() => runApp(const Map());

void main() {
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
            image: AssetImage('images/pacerunner4.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              const Icon(
                Icons.run_circle,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              ElevatedButton(
                  child: const Text('Click to Start Running'),
                  onPressed: () {
                    final trackingNotifier =
                        ref.read(trackingProvider.notifier);
                    if (isTracking) {
                      trackingNotifier.state = false;
                      print(
                          'Traveled distance: ${ref.read(distanceProvider).toStringAsFixed(2)} km');
                    } else {
                      trackingNotifier.state = true;
                      ref.read(distanceProvider.notifier).state = 0.0;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CurrentRun()),
                    );
                  }),
              ElevatedButton(
                  child: const Text('Progress Bar Demo'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProgressBar()),
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}

class ThirdScreen extends StatelessWidget {
  const ThirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Run'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(
              height: 300,
              child: Map(),
            ),
            OverflowBar(
              alignment: MainAxisAlignment.start,
              children: <Widget>[
                TextButton(
                    child: const Text('Full Screen Map'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Map()),
                      );
                    }),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const AboutScreen(tag: 'visca')), // HERO
                    );
                  },
                  child: Hero(
                    // HERO
                    tag: 'visca', // Use the tag // HERO
                    child: Image.asset(
                      'images/FCB.png',
                      width: 50, // Set the desired width
                      height: 50, // Set the desired height
                    ),
                  ),
                ),
                const MyButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  final String tag; //HERO
  const AboutScreen({required this.tag, super.key}); //HERO

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text('About Page'),
      ),
      body: Center(
        child: Hero(
          tag: tag, //HERO
          child: Image.asset('images/FCB.png'),
        ),
      ),
    );
  }
}

class MyButton extends StatelessWidget {
  const MyButton({super.key});

  @override
  Widget build(BuildContext context) {
    // The GestureDetector wraps the button.
    return GestureDetector(
      // When the child is tapped, show a snackbar.
      onTap: () {
        const snackBar = SnackBar(content: Text('Cosquillas'));

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
      // The custom button
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.lightBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('My Button'),
      ),
    );
  }
}
