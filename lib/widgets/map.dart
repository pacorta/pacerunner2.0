import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'distance_provider.dart';
import 'tracking_provider.dart';
import 'speed_provider.dart';
import 'run_state_provider.dart';
import 'map_controller_provider.dart';
import '../services/location_service.dart';
import 'dart:math' as math;

// ---- Tuning constants ----
const double kRejectAccuracy = 35.0; // descarta puntos con accuracy peor a esto
const double kMinStepFloor = 3.0; // umbral mínimo absoluto (m)
const double kMinStepCeil = 12.0; // umbral máximo absoluto (m)
const double kAccFactor = 0.5; // cuánto escala con la accuracy (m por m)
const double kGoodAccCutoff = 10.0; // si accuracy es muy buena, usamos 2 m
const double kGoodAccStep = 2.0; // umbral con buena accuracy
const double kSpeedMax = 15.0; // m/s (≈54 km/h)
const double kAnchorTimeoutS = 30.0; // segundos sin movimiento "real"

class Map extends ConsumerStatefulWidget {
  const Map({super.key});

  @override
  ConsumerState<Map> createState() => _MapState();
}

class _MapState extends ConsumerState<Map> {
  GoogleMapController? mapController;
  LatLng _currentPosition = const LatLng(0, 0);

  // Polyline points
  List<LatLng> polylineCoordinates = [];

  // Speed
  double _currentSpeed = 0.0;
  double getSpeedInMph() {
    return _currentSpeed * 2.23694;
  }

  // Calculate Distance Travelled
  final List<LocationData> _locations = [];

  // Filtered distance state (anchor-gate)
  LocationData? _anchorLocation;
  RunState? _previousRunState; // track previous run state for re-anchoring

  StreamSubscription<LocationData>? _locationServiceSubscription;

  @override
  void initState() {
    super.initState();
    // Prime initial location for immediate map position
    _primeInitialLocation();
    // Listen to LocationService stream instead of creating own GPS
    _listenToLocationService();
  }

  Future<void> _primeInitialLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (!mounted) return;
    if (loc != null && loc.latitude != null && loc.longitude != null) {
      setState(() {
        _currentPosition = LatLng(loc.latitude!, loc.longitude!);
      });
    }
  }

  //Function to listen to LocationService stream
  void _listenToLocationService() {
    print('Map: Subscribing to LocationService stream...');

    _locationServiceSubscription = LocationService.locationStream.listen(
      (LocationData currentLocation) {
        //print('Map: Received location update from service');

        if (!mounted) return;

        final isTracking = ref.read(trackingProvider);
        final runState = ref.read(runStateProvider); // Leer run state

        if (!isTracking) {
          _cleanupLocationTracking();
          return;
        }

        // Re-anchor on critical state changes before setState
        if (_previousRunState != null && _previousRunState != runState) {
          if (runState == RunState.paused ||
              (runState == RunState.running &&
                  _previousRunState == RunState.paused)) {
            _anchorLocation = null;
            print(
                'GPS Filter: Re-anchoring due to state change: $_previousRunState -> $runState');
          }
        }
        _previousRunState = runState;

        setState(() {
          _currentPosition =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _currentSpeed = currentLocation.speed ?? 0.0;

          // Update speed provider
          double speedInMph = getSpeedInMph();
          ref.read(speedProvider.notifier).state = speedInMph;

          // SIEMPRE agregar ubicación (para mantener continuidad)
          if (ref.read(trackingProvider)) {
            // Solo calcular distancia si el estado es RUNNING
            if (runState == RunState.running) {
              final deltaKm = _maybeComputeFilteredDeltaKm(currentLocation);
              if (deltaKm != null && deltaKm > 0) {
                ref.read(distanceProvider.notifier).state += deltaKm;
              }
            }

            // SIEMPRE agregar ubicación (para mantener continuidad)
            _locations.add(currentLocation);
            // Actualizar provider para compartir con current_run.dart
            ref.read(locationsProvider.notifier).state = [..._locations];
          }

          // Solo actualizar polyline si el estado es RUNNING o PAUSED
          if (runState == RunState.running || runState == RunState.paused) {
            LatLng newPoint =
                LatLng(currentLocation.latitude!, currentLocation.longitude!);
            _updatePolyline(newPoint);
          }

          // Update camera (SIEMPRE para mostrar ubicación actual)
          if (mapController != null) {
            mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: _currentPosition, zoom: 20),
              ),
            );
          }
        });
      },
      onError: (error) {
        print('Map: Error receiving location updates - $error');
      },
    );
  }

  // December 3, 2024: all cleanup operations in 1 function
  void _cleanupLocationTracking() {
    _locations.clear(); // Clears stored location history
    polylineCoordinates.clear(); // Clears the route line on the map

    // reset filtered distance anchor
    _anchorLocation = null;
    _previousRunState = null; // reset previous state

    // limpiar providers con try-catch
    try {
      ref.read(locationsProvider.notifier).state = [];
      ref.read(polylineCoordinatesProvider.notifier).state = [];
    } catch (e) {
      // Widget disposed, ignorar
      print('Map: cleanup() - Provider cleanup failed (widget disposed): $e');
    }
  }

  @override
  void dispose() {
    //Cancel LocationService subscription instead of own subscription
    _locationServiceSubscription?.cancel();
    mapController?.dispose();

    // limpiar provider con try-catch para evitar crashes
    try {
      ref.read(mapControllerProvider.notifier).state = null;
    } catch (e) {
      // Widget disposed, ignorar
      print('Map: dispose() - Provider cleanup failed (widget disposed): $e');
    }

    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // actualizar provider para compartir con current_run.dart
    ref.read(mapControllerProvider.notifier).state = controller;
  }

  void _updatePolyline(LatLng newPoint) {
    if (mounted) {
      setState(() {
        polylineCoordinates.add(newPoint);
      });
      // actualizar provider para compartir con current_run.dart
      ref.read(polylineCoordinatesProvider.notifier).state = [
        ...polylineCoordinates
      ];
    }
  }

  // Removed _getCurrentLocation() async { ... }
  // We don't need this function because LocationService handles everything

  double _calculateDistanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // PI / 180
    var c = math.cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742000 * math.asin(math.sqrt(a)); // [m]
  }

  double? _maybeComputeFilteredDeltaKm(LocationData current) {
    final acc = current.accuracy;
    // 1) Precisión: descarta sin mover ancla
    if (acc != null && acc > kRejectAccuracy) return null;

    // 2) Inicializa ancla
    if (_anchorLocation == null) {
      _anchorLocation = current;
      return null;
    }

    final prev = _anchorLocation!;
    if ([prev.latitude, prev.longitude, current.latitude, current.longitude]
        .any((e) => e == null)) return null;

    // 3) Distancia desde el ANCLA
    final dMeters = _calculateDistanceMeters(
      prev.latitude!,
      prev.longitude!,
      current.latitude!,
      current.longitude!,
    );

    // 4) Chequeos de velocidad y timeout (solo si tenemos timestamps)
    final t0 = prev.time, t1 = current.time;
    if (t0 != null && t1 != null && t1 > t0) {
      final dt = (t1 - t0) / 1000.0; // s
      if (dt > 0) {
        final v = dMeters / dt; // m/s
        if (v > kSpeedMax) return null; // teletransporte -> rechaza
      }
      // Si pasó mucho tiempo y no hubo movimiento real, reancla (evita arrastre)
      if (dt > kAnchorTimeoutS && dMeters < 10.0) {
        _anchorLocation = current;
        return null;
      }
    }

    // 5) Umbral dinámico razonable
    final accM = acc ?? 25.0;
    final double minStep = (accM < kGoodAccCutoff)
        ? kGoodAccStep
        : math.max(kMinStepFloor, math.min(kMinStepCeil, accM * kAccFactor));

    // 6) Acepta solo si supera el radio desde el ancla
    if (dMeters < minStep) return null;

    _anchorLocation = current;
    return dMeters / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    // Listen for tracking changes
    ref.listen(trackingProvider, (previous, next) {
      if (!next) {
        _cleanupLocationTracking();
      }
    });

    // Render map immediately without internal spinner or nested MaterialApp/Scaffold
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        gradient: const SweepGradient(
          center: Alignment.center,
          startAngle: 0.0,
          endAngle: 3.14159,
          colors: [
            Color.fromRGBO(140, 82, 255, 1.0),
            Color.fromRGBO(255, 87, 87, 1.0),
          ],
        ),
      ),
      padding: const EdgeInsets.all(3.0), // Grosor del borde
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9.0),
          color: Colors.transparent,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9.0),
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 15.0,
            ),
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylineCoordinates,
                color: const Color.fromARGB(255, 255, 49, 49),
                width: 5,
              ),
            },
          ),
        ),
      ),
    );
  }
}
