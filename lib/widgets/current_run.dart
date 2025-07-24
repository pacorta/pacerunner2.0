import 'package:flutter/material.dart';
import 'package:untitled/widgets/elapsed_time_provider.dart';
import 'dart:async';
import 'map.dart';
import 'tracking_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'speed_provider.dart';
import 'distance_provider.dart';
import 'average_pace_provider.dart';
//import 'current_pace_in_seconds_provider.dart';
import 'current_pace_provider.dart';
import 'pace_bar.dart';

import '../firebase/firebaseWidgets/running_stats.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'distance_unit_as_string_provider.dart';

//import 'tracking_provider.dart';

import 'current_pace_in_seconds_provider.dart';
import 'gps_indicator.dart';

import 'run_state_provider.dart';
import 'pausable_timer_provider.dart';

class CurrentRun extends ConsumerStatefulWidget {
  const CurrentRun({super.key});

  @override
  ConsumerState<CurrentRun> createState() => _CurrentRunState();
}

class _CurrentRunState extends ConsumerState<CurrentRun> {
  @override
  void initState() {
    super.initState();

    // Iniciar el run automáticamente cuando se carga la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(runStateProvider.notifier).state = RunState.running;
      ref.read(pausableTimerProvider.notifier).start();
    });
  }

  // Función para pausar run
  void _pauseRun() {
    ref.read(pausableTimerProvider.notifier).pause();
    ref.read(runStateProvider.notifier).state = RunState.paused;
  }

  void _resumeRun() {
    ref.read(pausableTimerProvider.notifier).resume();
    ref.read(runStateProvider.notifier).state = RunState.running;
  }

  void _endRun() {
    // Paso 1: Capturar datos antes de resetear
    String distanceString = ref.read(formattedDistanceProvider).split(' ')[0];
    double distance = double.tryParse(distanceString) ?? 0.0;
    String distanceUnitString = ref.read(formattedUnitString);
    final finalTime = ref.read(formattedElapsedTimeProvider);
    final finalPace = ref.read(averagePaceProvider);

    // Paso 2: Ahora si, resetear cronómetro y cambiar estado
    ref.read(pausableTimerProvider.notifier).stop();
    ref.read(runStateProvider.notifier).state = RunState.finished;

    // Paso 3: Para el tracking GPS inmediatamente
    ref.read(trackingProvider.notifier).state = false;

    // Paso 4: Usar los datos capturados (que YA tienen los valores correctos)
    final runData = {
      'distance': distance,
      'distanceUnitString': distanceUnitString,
      'time': finalTime, // Ya tiene el tiempo correcto
      'averagePace': finalPace, // Ya tiene el pace correcto
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Show the alert dialog with summary stats
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Run Completed'),
        content: Text(
          'Run Time: $finalTime\n'
          'Traveled Distance: $distance $distanceUnitString\n'
          'Average Pace: $finalPace',
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () async {
              //(1) Reset Providers (tracking ya está en false)
              ref.read(distanceProvider.notifier).state = 0.0;
              ref.read(speedProvider.notifier).state = 0.0;
              ref.read(elapsedTimeProvider.notifier).state = '00:00:00';
              resetCurrentPaceInSecondsProvider();
              resetCurrentPaceProvider();

              //(2) Pop Dialog and Navigate to Running Stats Page
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => RunningStatsPage(newRunData: runData),
                ),
              );

              //(3) Save the run data to Firebase
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('runs')
                    .add(runData)
                    .then((_) {
                  debugPrint('Run saved successfully');
                }).catchError((error) {
                  debugPrint('Error saving run: $error');
                });
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDistance = ref.watch(formattedDistanceProvider);
    final elapsedTime = ref.watch(formattedElapsedTimeProvider);
    final currentPace = ref.watch(currentPaceProvider);
    final runState = ref.watch(runStateProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Current Run - ${getRunStateText(runState)}'),
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  const SizedBox(height: 500, child: Map()),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        elapsedTime,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const Positioned(top: 10, right: 10, child: GPSIndicator()),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  PaceBar(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 60.0,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'CURRENT PACE: $currentPace',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'DISTANCE: $formattedDistance',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildControlButtons(runState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Botones que cambian según el estado del run
  Widget _buildControlButtons(RunState runState) {
    switch (runState) {
      case RunState.running:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _pauseRun,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pause, color: Colors.white),
                    SizedBox(width: 8),
                    Text('PAUSE',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        );

      case RunState.paused:
        return Row(
          children: [
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: _resumeRun,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, color: Colors.white),
                    SizedBox(width: 4),
                    Text('RESUME',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: _endRun,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stop, color: Colors.white),
                    SizedBox(width: 4),
                    Text('FINISH',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        );

      default:
        return Container(); // No mostrar botones en otros estados
    }
  }
}
