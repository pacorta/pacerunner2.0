import 'package:flutter/material.dart';

import 'widgets/map.dart';
import 'widgets/current_run.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void gmaps() => runApp(const Map());

void main() {
  runApp(
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'The Pacerunner Home Screen'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
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
            image: AssetImage('images/pacerunner3.png'),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CurrentRun()),
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
