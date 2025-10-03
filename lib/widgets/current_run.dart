import 'package:flutter/material.dart';
import 'package:pacerunner/widgets/elapsed_time_provider.dart';
import 'dart:async';
import 'package:location/location.dart';
import 'dart:typed_data';

import 'map.dart';
import 'tracking_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'speed_provider.dart';
import 'distance_provider.dart';
import 'goal_progress_provider.dart';
import 'stable_average_pace_provider.dart';
import 'projected_finish_provider.dart';
import 'prediction_display.dart';
import 'current_pace_provider.dart';
import 'pace_bar.dart';
import 'map_controller_provider.dart';

import 'gps_indicator.dart';
import 'run_state_provider.dart';
import 'pausable_timer_provider.dart';
import 'readable_pace_provider.dart';
import 'custom_pace_provider.dart';
import 'custom_distance_provider.dart';
import 'distance_unit_as_string_provider.dart';
import 'distance_unit_conversion.dart';
import 'current_pace_in_seconds_provider.dart';
import 'target_providers.dart';
import 'distance_unit_provider.dart';
import 'inline_goal_input.dart';

import 'run_summary_screen.dart';

import '../services/location_service.dart';
import 'gps_status_provider.dart';
import 'live_activity_provider.dart';
import '../services/live_activity_service.dart';
import '../services/run_save_service.dart';

class CurrentRun extends ConsumerStatefulWidget {
  const CurrentRun({super.key});

  @override
  ConsumerState<CurrentRun> createState() => _CurrentRunState();
}

class _CurrentRunState extends ConsumerState<CurrentRun> {
  Timer? _gpsTimeoutTimer;
  bool _hasTransitioned = false; //Para evitar transiciones múltiples
  DateTime? _runStartTime;
  // Sutil banners state
  GPSStatus? _lastGPSStatus;
  bool _showAcquiredBanner = false;
  Timer? _acquiredTimer;
  bool _userActed = false; // Start o Discard
  // First-fix shortcut to remove loader as soon as we have any location
  StreamSubscription<LocationData>? _firstFixSub;

  @override
  void initState() {
    super.initState();

    // Initialize Live Activity provider and GPS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start watching live activity provider to set up listeners
      ref.read(liveActivityProvider);

      ref.read(runStateProvider.notifier).state = RunState.fetchingGPS;
      _initializeGPS();
      _setupGPSTimeout();

      // Quitar loader en cuanto llegue el primer fix (aunque sea weak)
      _firstFixSub = LocationService.locationStream.listen((loc) {
        if (!mounted) return;
        final st = ref.read(runStateProvider);
        if (st == RunState.fetchingGPS) {
          ref.read(runStateProvider.notifier).state = RunState.readyToStart;
          _gpsTimeoutTimer?.cancel();
          _hasTransitioned = true;
        }
        _firstFixSub?.cancel();
        _firstFixSub = null;
      });
    });
  }

  //Inicializar GPS
  void _initializeGPS() async {
    print('CurrentRun: Initializing GPS...');

    // Inicializar LocationService con ref
    LocationService.initialize(ref);

    // Verificar si el usuario rechazó permisos permanentemente antes
    final permissionStatus = await LocationService.getPermissionStatus();

    if (permissionStatus == PermissionStatus.deniedForever) {
      // Usuario rechazó y dijo "Don't ask again" - ir directo a Settings
      if (mounted) {
        ref.read(runStateProvider.notifier).state = RunState.readyToStart;
        _showLocationDeniedForeverDialog();
      }
      return;
    }

    // Empezar tracking GPS con prompts habilitados
    final success = await LocationService.startLocationTracking(
      promptIfDenied: true,
      elevateToAlways: true,
    );

    if (!success) {
      // Verificar nuevamente si fue un rechazo activo
      final newStatus = await LocationService.getPermissionStatus();
      if (mounted) {
        ref.read(runStateProvider.notifier).state = RunState.readyToStart;

        if (newStatus == PermissionStatus.denied ||
            newStatus == PermissionStatus.deniedForever) {
          // Usuario rechazó activamente - diálogo fuerte
          _showLocationRequiredDialog();
        } else {
          // Error técnico normal
          _showGPSError();
        }
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

  // Mostrar error de GPS (problemas técnicos)
  void _showGPSError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('GPS not available. You can start without precise location.'),
        backgroundColor: const Color(0xFFFFB6C1),
      ),
    );
  }

  // Mostrar diálogo cuando usuario rechazó permisos activamente
  void _showLocationRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.red.shade600, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Location Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pacebud needs location access to track your run accurately.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF34495E),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Return to home
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Return to home first
              final opened = await LocationService.openAppSettings();
              if (!opened) {
                print('CurrentRun: Could not open app settings');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar diálogo cuando permisos están permanentemente denegados
  void _showLocationDeniedForeverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.orange.shade600, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Enable Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location access is currently disabled for Pacebud.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF34495E),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'To enable location:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Tap "Open Settings" below\n2. Find "Location" or "Privacy"\n3. Enable location for Pacebud',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF34495E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Return to home
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Return to home first
              final opened = await LocationService.openAppSettings();
              if (!opened) {
                print('CurrentRun: Could not open app settings');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Verificar estado de Location Services y mostrar mensaje si están deshabilitados
  void _checkLocationServiceStatus() async {
    final isAvailable = await LocationService.isLocationServiceAvailable();
    if (!isAvailable && mounted) {
      _showLocationServiceDisabledBanner();
    }
  }

  // Mostrar banner persistente cuando Location Services están deshabilitados
  void _showLocationServiceDisabledBanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.location_off, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Location Services disabled. Please enable in Settings for accurate tracking.'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 8), // Más tiempo para que user lo vea
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () async {
            final opened = await LocationService.openAppSettings();
            if (!opened) {
              print('CurrentRun: Could not open system settings');
            }
          },
        ),
      ),
    );
  }

  // Empezar run
  void _startRun() {
    _runStartTime = DateTime.now(); // ← CAPTURAR HORA DE INICIO
    print('CurrentRun: Starting run...');
    _userActed = true;
    ref.read(runStateProvider.notifier).state = RunState.running;
    ref.read(pausableTimerProvider.notifier).start();

    // Record goal mode at start
    final hasDistance = ref.read(customDistanceProvider) != null;
    final hasPace = ref.read(customPaceProvider) != null;
    final hasDistanceTimeGoal = hasDistance && hasPace;
    ref.read(hadDistanceTimeGoalProvider.notifier).state = hasDistanceTimeGoal;
    ref.read(hadDistanceOnlyGoalProvider.notifier).state =
        hasDistance && !hasPace;
    // Time-only: we represent it by having neither distance nor pace
    ref.read(hadTimeOnlyGoalProvider.notifier).state = !hasDistance && !hasPace;
  }

  @override
  void dispose() {
    _gpsTimeoutTimer?.cancel();
    _acquiredTimer?.cancel();
    _firstFixSub?.cancel();

    // SIEMPRE parar LocationService al salir de CurrentRun
    // Usamos reset() en lugar de dispose() para mantener StreamController disponible
    // ignore: unawaited_futures
    LocationService.reset().then((_) {
      print('CurrentRun: dispose() - LocationService reset successfully');
    }).catchError((e) {
      // Si ref no está disponible, no importa - al menos cancelamos GPS
      print('CurrentRun: dispose() - Error resetting LocationService: $e');
    });

    super.dispose();
  }

  // Función para pausar run
  void _pauseRun() async {
    // Pausar el cronómetro
    ref.read(pausableTimerProvider.notifier).pause();

    // Pausar el tracking de GPS para ahorrar batería
    await LocationService.pauseLocationTracking();

    // Cambiar estado
    ref.read(runStateProvider.notifier).state = RunState.paused;
  }

  void _resumeRun() async {
    // Reanudar el cronómetro
    ref.read(pausableTimerProvider.notifier).resume();

    // Reanudar el tracking de GPS con máxima precisión
    await LocationService.resumeLocationTracking();

    // Cambiar estado
    ref.read(runStateProvider.notifier).state = RunState.running;
  }

  void _endRun() async {
    // Paso 1: Parar GPS DIRECTAMENTE (sin activar cleanup en map.dart)
    await LocationService.stopLocationTracking();
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

    // Paso 4: Capturar datos antes de resetear (usar distancia cruda con precisión)
    final distanceKmRaw = ref.read(distanceProvider);
    final unit = ref.read(distanceUnitProvider);
    double distance = unit == DistanceUnit.miles
        ? kilometersToMiles(distanceKmRaw)
        : distanceKmRaw;
    String distanceUnitString = ref.read(formattedUnitString);
    final finalTime = ref.read(formattedElapsedTimeProvider);
    final finalPace = ref.read(stableAveragePaceProvider);

    // Validar distancia minima antes de continuar
    if (distance < 0.01) {
      _showNoMovementDialog();
      return;
    }

    // Guardar el run inmediatamente (antes de navegar a resumen)
    String? savedRunDocId;
    try {
      final runData = RunSaveService.buildRunData(
        ref: ref,
        distance: distance,
        distanceUnitString: distanceUnitString,
        finalTime: finalTime,
        finalPace: finalPace,
        runStartTime: _runStartTime,
      );
      savedRunDocId = await RunSaveService.saveRunData(runData);
      // ignore: avoid_print
      print('CurrentRun: run saved at FINISH with docId: $savedRunDocId');
      await LiveActivityService.endRunningActivity();
    } catch (e) {
      // ignore: avoid_print
      print('CurrentRun: error saving run at FINISH: $e');
    }

    // Paso 5: Ahora si reseteamos el cronómetro y cambiamos el estado
    ref.read(pausableTimerProvider.notifier).stop();
    ref.read(runStateProvider.notifier).state = RunState.finished;

    // Navigate to RunSummaryScreen
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RunSummaryScreen(
          mapSnapshot: mapSnapshot,
          distance: distance,
          distanceUnitString: distanceUnitString,
          finalTime: finalTime,
          finalPace: finalPace,
          runStartTime: _runStartTime,
          savedRunDocId: savedRunDocId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child; // No transition, just show the page
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  // Discard confirmation dialog
  void _showDiscardConfirmation(BuildContext context,
      {bool closeMainDialog = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red.shade600, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Discard Run',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to discard this run?',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF34495E),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This action cannot be undone. All your progress will be lost.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Keep Run',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close the confirmation dialog
                Navigator.of(context).pop();

                // If this confirmation was opened on top of the summary dialog,
                // close the summary dialog as well
                if (closeMainDialog) {
                  Navigator.of(context).pop();
                }

                _userActed = true; // dejar de mostrar banners sutiles
                // Stop GPS/location tracking immediately
                try {
                  await LocationService.stopLocationTracking();
                } catch (_) {}

                // Ensure tracking is disabled so Map ignores updates until next run
                try {
                  ref.read(trackingProvider.notifier).state = false;
                } catch (_) {}

                // Stop and reset timer
                try {
                  ref.read(pausableTimerProvider.notifier).stop();
                } catch (_) {}

                // Reset run state so next session starts fresh
                try {
                  ref.read(runStateProvider.notifier).state =
                      RunState.fetchingGPS;
                } catch (_) {}

                // Reset metrics and computed providers
                try {
                  ref.read(distanceProvider.notifier).state = 0.0;
                  ref.read(speedProvider.notifier).state = 0.0;
                } catch (_) {}
                try {
                  ref.read(elapsedTimeProvider.notifier).state = '00:00:00';
                } catch (_) {}
                resetCurrentPaceInSecondsProvider();
                resetCurrentPaceProvider();
                resetStableAveragePace(ref);
                resetPredictionProviders(ref);

                // Clear any active goal so Home shows blank after discard
                try {
                  clearGoalProviders(ref);
                } catch (_) {}

                // Clear route-related shared state to avoid stale polylines
                try {
                  ref.read(locationsProvider.notifier).state = [];
                  ref.read(polylineCoordinatesProvider.notifier).state = [];
                } catch (_) {}

                // Navigate back to root (RootShell) to restore bottom nav
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Discard Run',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNoMovementDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade800,
          title: const Text(
            'No Movement Detected',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: const Text(
            'This activity cannot be saved because there\'s no change in your location',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog

                // Discard the run (similar to _showDiscardConfirmation logic)
                _userActed = true;
                try {
                  await LocationService.stopLocationTracking();
                } catch (_) {}
                try {
                  ref.read(trackingProvider.notifier).state = false;
                } catch (_) {}
                try {
                  ref.read(pausableTimerProvider.notifier).stop();
                } catch (_) {}
                try {
                  ref.read(runStateProvider.notifier).state =
                      RunState.fetchingGPS;
                } catch (_) {}
                try {
                  ref.read(distanceProvider.notifier).state = 0.0;
                  ref.read(speedProvider.notifier).state = 0.0;
                } catch (_) {}
                try {
                  ref.read(elapsedTimeProvider.notifier).state = '00:00:00';
                } catch (_) {}
                resetCurrentPaceInSecondsProvider();
                resetCurrentPaceProvider();
                resetStableAveragePace(ref);
                resetPredictionProviders(ref);
                try {
                  clearGoalProviders(ref);
                } catch (_) {}
                try {
                  ref.read(locationsProvider.notifier).state = [];
                  ref.read(polylineCoordinatesProvider.notifier).state = [];
                } catch (_) {}
                await LiveActivityService.endRunningActivity();

                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text(
                'Discard',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runStateProvider);

    // Listen for distance crossing the target distance to capture first reach time
    ref.listen<double>(distanceProvider, (previous, current) {
      final targetDistance = ref.read(targetDistanceProvider);
      final unit = ref.read(distanceUnitProvider);
      final alreadyCaptured =
          ref.read(firstReachTargetTimeSecondsProvider) != null;

      if (targetDistance == null || alreadyCaptured) {
        return;
      }

      // Convert target distance to km to compare with distanceProvider (km)
      double targetDistanceKm = targetDistance;
      if (unit == DistanceUnit.miles) {
        targetDistanceKm = targetDistance * 1.60934;
      }

      final prev = previous ?? 0.0;
      if (prev < targetDistanceKm && current >= targetDistanceKm) {
        final secs = ref.read(elapsedTimeInSecondsProvider);
        final str = ref.read(formattedElapsedTimeProvider);
        ref.read(firstReachTargetTimeSecondsProvider.notifier).state = secs;
        ref.read(firstReachTargetTimeStringProvider.notifier).state = str;
      }
    });

    // GPS listener DENTRO del build method
    ref.listen(gpsStatusProvider, (previous, next) {
      final currentState = ref.read(runStateProvider);

      // Transicionar a readyToStart cuando dejemos de estar "acquiring"
      if (currentState == RunState.fetchingGPS && !_hasTransitioned) {
        if (next != GPSStatus.acquiring) {
          print('CurrentRun: GPS fix obtained (any accuracy), readyToStart');
          ref.read(runStateProvider.notifier).state = RunState.readyToStart;
          _gpsTimeoutTimer?.cancel();
          _hasTransitioned = true;
        }
      }

      // Banner momentáneo cuando pasamos de weak/acquiring a good/strong
      final wasWeakOrAcquiring = _lastGPSStatus == GPSStatus.weak ||
          _lastGPSStatus == GPSStatus.acquiring;
      final isGoodNow = next == GPSStatus.good || next == GPSStatus.strong;
      if (wasWeakOrAcquiring && isGoodNow && !_userActed) {
        setState(() => _showAcquiredBanner = true);
        _acquiredTimer?.cancel();
        _acquiredTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showAcquiredBanner = false);
        });
      }

      _lastGPSStatus = next;
    });

    // Listen for location service issues during active run
    ref.listen(gpsStatusProvider, (previous, next) {
      final currentState = ref.read(runStateProvider);

      // Si estamos corriendo y GPS se vuelve muy malo, podría ser que user apagó Location Services
      if ((currentState == RunState.running ||
              currentState == RunState.paused) &&
          next == GPSStatus.acquiring &&
          previous != GPSStatus.acquiring) {
        print(
            'CurrentRun: GPS signal lost during run, checking location service...');
        _checkLocationServiceStatus();
      }
    });

    final elapsedTime = ref.watch(formattedElapsedTimeProvider);
    final distance = ref.watch(formattedDistanceProvider);
    final averagePace = ref.watch(stableAveragePaceProvider);

    return PopScope(
      canPop: false, // Disable back button and slide-back gesture
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 17, 17, 17),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // HEADER SECTION - Siempre visible
                _buildHeaderSection(runState),

                // MAIN CONTENT SECTION: mostrar SIEMPRE el mapa
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: const Map(),
                ),

                // DATOS DEL RUN - Siempre visibles
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: <Widget>[
                        // Banner sutil de GPS: solo cuando ya no estamos en fetchingGPS
                        if (!_userActed && runState != RunState.fetchingGPS)
                          _buildGPSStatusBanner(),
                        const SizedBox(height: 8),
                        // Tiempo transcurrido - Grande
                        Text(
                          elapsedTime,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Etiqueta de tiempo
                        const Text(
                          'time',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Distancia y Pace en fila
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Distancia
                            Column(
                              children: [
                                Text(
                                  distance.split(' ')[0], // Solo el número
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'distance (${distance.split(' ').length > 1 ? distance.split(' ')[1] : 'km'})',
                                  style: const TextStyle(
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
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

                        const SizedBox(height: 24),

                        // PaceBar - Solo cuando run está activo Y hay target pace: APAGADO PARA MVP
                        //_buildPaceBarSection(runState),

                        // Prediction Display - Solo cuando hay target pace
                        _buildPredictionSection(runState),

                        const Spacer(),

                        // Botones de control (muestran spinner en fetchingGPS)
                        _buildControlButtons(runState),

                        // Discard run
                        if (runState == RunState.readyToStart)
                          OutlinedButton.icon(
                            onPressed: () => _showDiscardConfirmation(context),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.75),
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.30),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              minimumSize: const Size(double.infinity, 44),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 20),
                            label: const Text(
                              'Discard run',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header section con información del run y GPS indicator
  Widget _buildHeaderSection(RunState runState) {
    final readablePace = ref.watch(readablePaceProvider);

    // Usar el formato guardado si está disponible, sino usar texto por defecto
    String headerText = readablePace.isNotEmpty ? readablePace : "Run";

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
          SizedBox(height: 8),
        ],
      );
    }

    return SizedBox.shrink(); // No mostrar nada si no hay target pace
  }

  // Seccion de Prediction Display
  Widget _buildPredictionSection(RunState runState) {
    final customDistance = ref.watch(customDistanceProvider);

    // Show prediction if there's a distance goal (with or without time) and the run is active
    if (customDistance != null &&
        (runState == RunState.running || runState == RunState.paused)) {
      return Column(
        children: [
          PredictionDisplay(),
          SizedBox(height: 8),
        ],
      );
    }

    return SizedBox.shrink(); // No mostrar nada si no hay distance goal
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

  // Banner sutil inferior
  Widget _buildGPSStatusBanner() {
    final status = ref.watch(gpsStatusProvider);

    if (_showAcquiredBanner) {
      return _buildBanner(
        text: 'GPS signal acquired',
        color: Colors.green,
      );
    }

    switch (status) {
      case GPSStatus.acquiring:
        return const SizedBox.shrink(); // no duplicar con loader inferior
      case GPSStatus.weak:
        return _buildBanner(
          text: 'Weak GPS signal',
          color: Colors.redAccent,
        );
      case GPSStatus.good:
      case GPSStatus.strong:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBanner({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
