import 'package:flutter/material.dart';
import 'package:untitled/widgets/elapsed_time_provider.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'map.dart';
import 'tracking_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'speed_provider.dart';
import 'distance_provider.dart';
import 'average_pace_provider.dart';
import 'current_pace_provider.dart';
import 'pace_bar.dart';
import 'map_controller_provider.dart';

import '../firebase/firebaseWidgets/running_stats.dart';
import '../home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'distance_unit_as_string_provider.dart';
import 'current_pace_in_seconds_provider.dart';
import 'gps_indicator.dart';
import 'run_state_provider.dart';
import 'pausable_timer_provider.dart';
import 'readable_pace_provider.dart';
import 'custom_pace_provider.dart';
import 'custom_distance_provider.dart';
import 'run_summary_card.dart';

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
  DateTime? _runStartTime;
  final GlobalKey _repaintBoundaryKey = GlobalKey();

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
        backgroundColor: const Color(0xFFFFB6C1),
      ),
    );
  }

  // Empezar run
  void _startRun() {
    _runStartTime = DateTime.now(); // ← CAPTURAR HORA DE INICIO
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

  void _endRun() async {
    // Paso 1: Parar GPS DIRECTAMENTE (sin activar cleanup en map.dart)
    LocationService.stopLocationTracking();
    print('CurrentRun: GPS service stopped directly before screenshot');

    // Paso 2: Capturar screenshot (datos aún disponibles)
    Uint8List? mapSnapshot;
    try {
      final mapController = ref.read(mapControllerProvider);
      final locations = ref.read(locationsProvider);

      if (mapController != null && locations.isNotEmpty) {
        print('CurrentRun: Capturing map screenshot...');
        mapSnapshot = await captureMapScreenshot(mapController, locations);
      } else {
        print('CurrentRun: No map controller or locations for screenshot');
      }
    } catch (e) {
      print('CurrentRun: Error capturing map screenshot: $e');
    }

    // Paso 3: AHORA SÍ activar cleanup normal
    ref.read(trackingProvider.notifier).state = false;
    print('CurrentRun: Tracking stopped, cleanup activated');

    // Paso 4: Capturar datos antes de resetear
    String distanceString = ref.read(formattedDistanceProvider).split(' ')[0];
    double distance = double.tryParse(distanceString) ?? 0.0;
    String distanceUnitString = ref.read(formattedUnitString);
    final finalTime = ref.read(formattedElapsedTimeProvider);
    final finalPace = ref.read(averagePaceProvider);

    // Paso 5: Ahora si reseteamos el cronómetro y cambiamos el estado
    ref.read(pausableTimerProvider.notifier).stop();
    ref.read(runStateProvider.notifier).state = RunState.finished;

    // Paso 6: Usar los datos capturados (que YA tienen los valores correctos)
    final runData = {
      'distance': distance,
      'distanceUnitString': distanceUnitString,
      'time': finalTime, // Ya tiene el tiempo correcto
      'averagePace': finalPace, // Ya tiene el pace correcto
      'startTime': _runStartTime?.toIso8601String(),
      'date': _runStartTime?.toString().split(' ')[0],
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Show the alert dialog with summary stats
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // RepaintBoundary wraps the card for future PNG export
            RepaintBoundary(
              key: _repaintBoundaryKey,
              child: RunSummaryCard(
                mapSnapshot: mapSnapshot,
                distance: distance.toString(),
                pace: finalPace,
                time: finalTime,
                distanceUnit: distanceUnitString,
              ),
            ),

            const SizedBox(height: 24),

            // Buttons below the card (outside of RepaintBoundary)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Save run button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        //(1) Reset Providers (tracking ya está en false)
                        ref.read(distanceProvider.notifier).state = 0.0;
                        ref.read(speedProvider.notifier).state = 0.0;
                        ref.read(elapsedTimeProvider.notifier).state =
                            '00:00:00';
                        resetCurrentPaceInSecondsProvider();
                        resetCurrentPaceProvider();

                        //(2) Pop Dialog and Navigate to Running Stats Page
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RunningStatsPage(newRunData: runData),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Save run',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Share run button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _copyToClipboard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),

                      /* child: Column(
                      children: const [
                        Text('Goal-focused Run'),
                        Text(
                          'Best for 5k+/3.1mi runs',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),

                      child: const Text(
                        'Share run',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      */
                      child: Column(
                        children: [
                          Text(
                            'Share run',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Now is your only chance (sorry).',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Discard run button (smaller, red, discrete)
                  TextButton(
                    onPressed: () => _showDiscardConfirmation(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                    ),
                    child: const Text(
                      'Discard run',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Discard confirmation dialog
  void _showDiscardConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade800,
          title: const Text(
            'Discard Run',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to discard this run? This action cannot be undone.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close confirmation dialog
                Navigator.of(context).pop(); // Close main dialog

                // Reset providers without saving
                ref.read(distanceProvider.notifier).state = 0.0;
                ref.read(speedProvider.notifier).state = 0.0;
                ref.read(elapsedTimeProvider.notifier).state = '00:00:00';
                resetCurrentPaceInSecondsProvider();
                resetCurrentPaceProvider();

                // Navigate back to home screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ),
                );
              },
              child: const Text(
                'Discard',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Copy run summary to clipboard as PNG
  Future<void> _copyToClipboard() async {
    try {
      // Get the RepaintBoundary
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // Capture as image with high quality
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);

      // Convert to PNG bytes
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Copy to clipboard as base64 encoded image
      await Clipboard.setData(ClipboardData(
          text: "data:image/png;base64,${base64Encode(pngBytes)}"));

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Run summary copied to clipboard!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error copying to clipboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runStateProvider);

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
    final averagePace = ref.watch(averagePaceProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color.fromRGBO(140, 82, 255, 1.0),
              Color.fromRGBO(255, 87, 87, 1.0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER SECTION - Siempre visible
              _buildHeaderSection(runState),

              // MAIN CONTENT SECTION
              if (runState == RunState.fetchingGPS) ...[
                // UI especial para cuando estamos buscando GPS
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
                          child: GPSIndicator(),
                        ),
                        SizedBox(height: 40),

                        // Loading animation
                        CircularProgressIndicator(
                          color: const Color(0xFFFFB6C1),
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
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // MAPA - Más pequeño
                Container(
                  height:
                      MediaQuery.of(context).size.height * 0.3, // 30% de altura
                  child: const Map(),
                ),

                // DATOS DEL RUN - Siempre visibles
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Tiempo transcurrido - Grande
                        Text(
                          elapsedTime,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),

                        // Etiqueta de tiempo
                        Text(
                          'time',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),

                        SizedBox(height: 24),

                        // Distancia y Pace en fila
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Distancia
                            Column(
                              children: [
                                Text(
                                  distance.split(' ')[0], // Solo el número
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'distance (${distance.split(' ').length > 1 ? distance.split(' ')[1] : 'km'})',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),

                            // Average Pace
                            Column(
                              children: [
                                Text(
                                  averagePace.split(
                                      '/')[0], // Solo el tiempo antes del /
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'avg pace',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: 32),

                        // PaceBar - Solo cuando run está activo Y hay target pace
                        _buildPaceBarSection(runState),

                        Spacer(),

                        // Botones de control
                        _buildControlButtons(runState),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Header section con información del run y GPS indicator
  Widget _buildHeaderSection(RunState runState) {
    final readablePace = ref.watch(readablePaceProvider);

    // Usar el formato guardado si está disponible, sino usar texto por defecto
    String headerText = readablePace.isNotEmpty ? readablePace : "Current Run";

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          // Texto central del header
          Center(
            child: Text(
              headerText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // GPS Indicator en esquina superior derecha
          Positioned(
            top: 0,
            right: 0,
            child: GPSIndicator(),
          ),
        ],
      ),
    );
  }

  // Sección del PaceBar
  Widget _buildPaceBarSection(RunState runState) {
    final customPace = ref.watch(customPaceProvider);
    final customDistance = ref.watch(customDistanceProvider);

    // Solo mostrar PaceBar si hay target pace configurado y el run está activo
    if (customPace != null &&
        customDistance != null &&
        (runState == RunState.running || runState == RunState.paused)) {
      return Column(
        children: [
          PaceBar(
            width: MediaQuery.of(context).size.width * 0.85,
            height: 60.0,
          ),
          SizedBox(height: 16),
        ],
      );
    }

    return SizedBox.shrink(); // No mostrar nada si no hay target pace
  }

  // Botones que cambian según el estado del run
  Widget _buildControlButtons(RunState runState) {
    switch (runState) {
      case RunState.fetchingGPS:
        return Column(
          children: [
            CircularProgressIndicator(color: const Color(0xFFFFB6C1)),
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
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pause, color: Colors.black),
                    SizedBox(width: 8),
                    Text('PAUSE',
                        style: TextStyle(fontSize: 18, color: Colors.black)),
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
