import 'package:flutter/material.dart';
import 'package:untitled/widgets/elapsed_time_provider.dart';
import 'dart:async';
import 'map.dart';
import 'tracking_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'speed_provider.dart';
import 'distance_provider.dart';
import 'average_pace_provider.dart';
import 'current_pace_provider.dart';
import 'pace_bar.dart';

import '../firebase/firebaseWidgets/running_stats.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'distance_unit_as_string_provider.dart';
import 'current_pace_in_seconds_provider.dart';
import 'gps_indicator.dart';
import 'run_state_provider.dart';
import 'pausable_timer_provider.dart';

import '../services/location_service.dart';
import 'gps_status_provider.dart';

class CurrentRun extends ConsumerStatefulWidget {
  const CurrentRun({super.key});

  @override
  ConsumerState<CurrentRun> createState() => _CurrentRunState();
}

class _CurrentRunState extends ConsumerState<CurrentRun> {
  Timer? _gpsTimeoutTimer;
  bool _hasTransitioned = false; //Para evitar transiciones múltiples
  bool _runCompleted = false; //Flag para trackear si run fue completado

  @override
  void initState() {
    super.initState();

    // Solo GPS initialization, NO listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(runStateProvider.notifier).state = RunState.fetchingGPS;
      _initializeGPS();
      _setupGPSTimeout(); // Solo timeout, NO listener aquí
    });
  }

  //Inicializar GPS
  void _initializeGPS() async {
    print('CurrentRun: Initializing GPS...');

    // Inicializar LocationService con ref
    LocationService.initialize(ref);

    // Empezar tracking GPS
    final success = await LocationService.startLocationTracking();

    if (!success) {
      // Manejar error de GPS
      if (mounted) {
        ref.read(runStateProvider.notifier).state = RunState.readyToStart;
        _showGPSError();
      }
    }
  }

  // Listener para cambios de GPS
  void _setupGPSListener() {
    // Escuchar cambios en GPS status
    ref.listen(gpsStatusProvider, (previous, next) {
      final currentState = ref.read(runStateProvider);

      // Solo transicionar si estamos en fetchingGPS
      if (currentState == RunState.fetchingGPS) {
        if (next == GPSStatus.good || next == GPSStatus.strong) {
          print('CurrentRun: GPS ready, transitioning to readyToStart');
          ref.read(runStateProvider.notifier).state = RunState.readyToStart;
          _gpsTimeoutTimer?.cancel(); // Cancelar timeout
        }
      }
    });
  }

  // Timeout de GPS (30 segundos)
  void _setupGPSTimeout() {
    _gpsTimeoutTimer = Timer(Duration(seconds: 30), () {
      final currentState = ref.read(runStateProvider);
      if (currentState == RunState.fetchingGPS) {
        print('CurrentRun: GPS timeout, allowing user to start anyway');
        ref.read(runStateProvider.notifier).state = RunState.readyToStart;
      }
    });
  }

  // Mostrar error de GPS
  void _showGPSError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('GPS not available. You can start without precise location.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Empezar run
  void _startRun() {
    print('CurrentRun: Starting run...');
    ref.read(runStateProvider.notifier).state = RunState.running;
    ref.read(pausableTimerProvider.notifier).start();
  }

  @override
  void dispose() {
    _gpsTimeoutTimer?.cancel();

    // SIEMPRE parar LocationService al salir de CurrentRun
    try {
      LocationService.stopLocationTracking();
      print('CurrentRun: dispose() - LocationService stopped successfully');
    } catch (e) {
      // Si ref no está disponible, no importa - al menos cancelamos GPS
      print('CurrentRun: dispose() - Error stopping LocationService: $e');
    }

    super.dispose();
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
    // marcar como completado antes de hacer cualquier cosa
    _runCompleted = true;

    // Paso 1: Capturar datos antes de resetear
    String distanceString = ref.read(formattedDistanceProvider).split(' ')[0];
    double distance = double.tryParse(distanceString) ?? 0.0;
    String distanceUnitString = ref.read(formattedUnitString);
    final finalTime = ref.read(formattedElapsedTimeProvider);
    final finalPace = ref.read(averagePaceProvider);

    // Paso 2: Ahora sí, resetear cronómetro y cambiar estado
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
    final runState = ref.watch(runStateProvider);
    final gpsStatus = ref.watch(gpsStatusProvider); // Watch GPS status

    // GPS listener DENTRO del build method
    ref.listen(gpsStatusProvider, (previous, next) {
      final currentState = ref.read(runStateProvider);

      // Solo transicionar si estamos en fetchingGPS y no hemos transicionado antes
      if (currentState == RunState.fetchingGPS && !_hasTransitioned) {
        if (next == GPSStatus.good || next == GPSStatus.strong) {
          print('CurrentRun: GPS ready, transitioning to readyToStart');
          ref.read(runStateProvider.notifier).state = RunState.readyToStart;
          _gpsTimeoutTimer?.cancel(); // Cancelar timeout
          _hasTransitioned = true; // Evitar transiciones múltiples
        }
      }
    });

    final elapsedTime = ref.watch(formattedElapsedTimeProvider);
    final distance = ref.watch(formattedDistanceProvider);
    final currentPace = ref.watch(currentPaceProvider);
    final averagePace = ref.watch(averagePaceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Run'),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
        ),
        child: Column(
          children: [
            // CONDICIONAL: Solo mostrar mapa y datos cuando GPS esté listo
            if (runState != RunState.fetchingGPS) ...[
              // Mapa (solo cuando no estamos buscando GPS)
              Expanded(
                flex: 3,
                child: const Map(),
              ),

              // Datos del run (solo cuando tenemos GPS)
              Container(
                color: const Color(0xFF1C1C1E),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Solo mostrar PaceBar cuando run está activo
                    if (runState == RunState.running ||
                        runState == RunState.paused) ...[
                      PaceBar(
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: 60.0,
                      ),
                      const SizedBox(height: 16),

                      // Current pace y distancia
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Current Pace',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  currentPace,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'Distance',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  distance,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // CONDICIONAL: Botones que cambian según el estado
                    _buildControlButtons(runState),
                  ],
                ),
              ),
            ],

            // UI especial para cuando estamos buscando GPS
            if (runState == RunState.fetchingGPS) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // GPS Status Indicator
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: GPSIndicator(), // Muestra el status del GPS
                      ),
                      SizedBox(height: 40),

                      // Loading animation
                      CircularProgressIndicator(
                        color: Colors.orange,
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 20),

                      // Mensaje explicativo
                      Text(
                        'Getting GPS signal...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please wait while we locate you',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),

                      // Debug info (temporal)
                      SizedBox(height: 20),
                      Text(
                        'GPS Status: ${gpsStatus.toString()}',
                        style: TextStyle(color: Colors.yellow, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Botones que cambian según el estado del run
  Widget _buildControlButtons(RunState runState) {
    switch (runState) {
      case RunState.fetchingGPS:
        return Column(
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Getting GPS signal...',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        );

      case RunState.readyToStart:
        return ElevatedButton(
          onPressed: _startRun,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow, color: Colors.white),
              SizedBox(width: 8),
              Text('START RUN',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ],
          ),
        );

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
