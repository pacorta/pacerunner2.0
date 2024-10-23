import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled/widgets/distance_unit_provider.dart';
import 'widgets/current_run.dart';
import 'widgets/tracking_provider.dart';
import 'widgets/distance_provider.dart';
import 'auth_wraper.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'firebase/firebaseWidgets/running_stats.dart';

import '/widgets/pace_selection.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isTracking = ref.watch(trackingProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthWrapper()),
              );
            },
          )
        ],
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
                      MaterialPageRoute(
                          builder: (context) => const CurrentRun()),
                    );
                  }),
              ElevatedButton(
                  child: const Text('Pace Selection'),
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
                      MaterialPageRoute(
                          builder: (context) => const PaceSelectionWidget()),
                    );
                  }),
              ElevatedButton(
                  child: const Text('Running Stats'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RunningStatsPage()),
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
