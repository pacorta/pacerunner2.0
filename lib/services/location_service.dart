import 'dart:async';
import 'package:location/location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/gps_status_provider.dart';

class LocationService {
  static final Location _location = Location();
  static StreamSubscription<LocationData>? _locationSubscription;
  static final StreamController<LocationData> _locationController =
      StreamController<LocationData>.broadcast();

  static bool _isInitialized = false;
  static WidgetRef? _ref;

  // Stream público que otros widgets pueden escuchar
  static Stream<LocationData> get locationStream => _locationController.stream;
  static bool get isInitialized => _isInitialized;

  // Inicializar el servicio con referencia de Riverpod
  static void initialize(WidgetRef ref) {
    _ref = ref;
  }

  // Iniciar tracking de ubicación (pre-warming)
  static Future<bool> startLocationTracking() async {
    if (_isInitialized) {
      print('LocationService: Already initialized');
      return true;
    }

    print('LocationService: Starting location tracking...');

    // Check permissions
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        print('LocationService: Location service not enabled');
        return false;
      }
    }

    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) {
        print('LocationService: Location permission not granted');
        return false;
      }
    }

    try {
      // Get initial location
      final locationData = await _location.getLocation();
      print('LocationService: Initial location acquired');

      // Try-catch para GPS status update
      _updateGPSStatusSafely(locationData.accuracy);

      // Start listening to location changes
      _locationSubscription = _location.onLocationChanged.listen(
        (LocationData currentLocation) {
          // Try-catch para GPS status update
          _updateGPSStatusSafely(currentLocation.accuracy);

          // Add to stream
          _locationController.add(currentLocation);
        },
        onError: (error) {
          print('LocationService: Location stream error: $error');
        },
      );

      _isInitialized = true;
      print('LocationService: Successfully initialized');
      return true;
    } catch (e) {
      print('LocationService: Error starting location tracking: $e');
      return false;
    }
  }

  //Update GPS status con try-catch
  static void _updateGPSStatusSafely(double? accuracy) {
    if (_ref != null) {
      try {
        final gpsStatus = determineGPSStatus(accuracy);
        _ref!.read(gpsStatusProvider.notifier).state = gpsStatus;
      } catch (e) {
        // Widget disposed, ignore GPS updates
        print(
            'LocationService: GPS status update failed (widget disposed): $e');
      }
    }
  }

  // Parar tracking de ubicación
  static void stopLocationTracking() {
    print('LocationService: Stopping location tracking...');

    // Cancel subscription
    _locationSubscription?.cancel();
    _locationSubscription = null;

    //Try-catch para final GPS status update
    if (_ref != null) {
      try {
        _ref!.read(gpsStatusProvider.notifier).state = GPSStatus.acquiring;
      } catch (e) {
        // Widget disposed, ignore
        print(
            'LocationService: Final GPS status update failed (widget disposed): $e');
      }
    }

    // Reset state
    _isInitialized = false;
    _ref = null;

    print('LocationService: Stopped');
  }

  // Cleanup completo
  static void dispose() {
    stopLocationTracking();
    _locationController.close();
    _ref = null;
  }

  // Get current location once (sin stream)
  static Future<LocationData?> getCurrentLocation() async {
    try {
      return await _location.getLocation();
    } catch (e) {
      print('LocationService: Error getting current location - $e');
      return null;
    }
  }
}
