import 'dart:async';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as ph; //alias
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/gps_status_provider.dart';
import 'native_location_manager.dart';

class LocationService {
  static final Location _location = Location();
  static StreamSubscription<LocationData>? _locationSubscription;
  static StreamController<LocationData>? _locationController;

  static bool _isInitialized = false;
  static bool _isStopping = false;
  static WidgetRef? _ref;

  // Asegurar que el controller existe y está abierto
  static void _ensureController() {
    if (_locationController == null || _locationController!.isClosed) {
      _locationController = StreamController<LocationData>.broadcast();
    }
  }

  // Stream público que otros widgets pueden escuchar
  static Stream<LocationData> get locationStream {
    _ensureController();
    return _locationController!.stream;
  }

  static bool get isInitialized => _isInitialized;

  // Inicializar el servicio con referencia de Riverpod
  static void initialize(WidgetRef ref) {
    _ref = ref;
  }

  // Iniciar tracking de ubicación (controlando prompts)
  static Future<bool> startLocationTracking({
    bool promptIfDenied = true,
    bool elevateToAlways = true,
  }) async {
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

    // Request permission logic (configurable)
    PermissionStatus permission = await _location.hasPermission();

    if (permission == PermissionStatus.denied) {
      if (!promptIfDenied) {
        print(
            'LocationService: Permission denied and promptIfDenied=false. Skipping.');
        return false;
      }
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) {
        print('LocationService: Location permission not granted');
        return false;
      }
    }

    // Handle deniedForever case - user needs to go to Settings to enable permission
    if (permission == PermissionStatus.deniedForever) {
      if (promptIfDenied) {
        print(
            'LocationService: Permission denied forever, opening app settings');
        final opened = await ph.openAppSettings();
        if (!opened) {
          print('LocationService: Could not open app settings');
        }
      } else {
        print(
            'LocationService: Permission denied forever and promptIfDenied=false. Skipping.');
      }
      return false;
    }

    // Check real iOS authorization status after permission request
    final status = await NativeLocationManager.authorizationStatus();
    if (status == 'whenInUse') {
      if (elevateToAlways) {
        print(
            'LocationService: Only "When In Use" permission granted. Requesting "Always" for background tracking...');
        await NativeLocationManager.requestAlways();

        // Check again after requestAlways
        final newStatus = await NativeLocationManager.authorizationStatus();
        if (newStatus != 'always') {
          print(
              'LocationService: "Always" permission not granted. Background tracking may be limited.');
        } else {
          print(
              'LocationService: "Always" permission granted. Full background tracking enabled.');
        }
      } else {
        print('LocationService: Authorization status: whenInUse');
      }
    } else if (status == 'always') {
      print('LocationService: "Always" permission already granted.');
    } else {
      print('LocationService: Authorization status: $status');
    }

    // Configure native iOS location manager for fitness tracking first
    await NativeLocationManager.configureForFitness();

    // Enable background mode and configure settings for fitness tracking
    await _location.enableBackgroundMode(enable: true);
    // Para adquisición inicial más rápida en reposo, usar alta precisión
    // y distanceFilter 0 (emite aunque no te muevas). Luego, al iniciar
    // la carrera, subimos a Navigation + 5m en resumeLocationTracking().
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000, // 1 second interval
      distanceFilter: 0, // updates también en reposo
    );

    try {
      // Get initial location
      final locationData = await _location.getLocation();
      print('LocationService: Initial location acquired');

      // Try-catch para GPS status update
      _updateGPSStatusSafely(locationData.accuracy);

      // Emitir ubicación inicial para evitar "hoyo" hasta el primer callback
      _ensureController();
      _locationController!.add(locationData);

      // Start listening to location changes
      _locationSubscription = _location.onLocationChanged.listen(
        (LocationData currentLocation) {
          // Try-catch para GPS status update
          _updateGPSStatusSafely(currentLocation.accuracy);

          // Add to stream (asegurar que controller existe)
          _ensureController();
          _locationController!.add(currentLocation);
        },
        onError: (error) async {
          print('LocationService: Location stream error: $error');

          // Intenta re-habilitar servicio / pedir permiso otra vez
          try {
            final ok = await _location.serviceEnabled() ||
                await _location.requestService();
            if (!ok) {
              print('LocationService: Could not re-enable location service');
              // Mostrar banner al usuario sobre location services deshabilitado
              _notifyLocationServiceDisabled();
            }
          } catch (e) {
            print(
                'LocationService: Error attempting to recover location service: $e');
          }
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
        // Widget disposed, clear ref to stop further attempts
        print(
            'LocationService: GPS status update failed (widget disposed): $e');
        _ref = null; // Clear ref to prevent further spam
      }
    }
  }

  // Notificar cuando Location Services están deshabilitados
  static void _notifyLocationServiceDisabled() {
    if (_ref != null) {
      try {
        // Cambiar GPS status a error para que UI pueda mostrar mensaje
        _ref!.read(gpsStatusProvider.notifier).state = GPSStatus.acquiring;
        print('LocationService: Location services disabled by user');
      } catch (e) {
        print(
            'LocationService: Could not notify location service disabled: $e');
        _ref = null; // Clear ref to prevent further attempts
      }
    }
  }

  // Pausar tracking de ubicación temporalmente (para ahorrar batería cuando se pausa la carrera)
  static Future<void> pauseLocationTracking() async {
    print('LocationService: Pausing location tracking...');
    try {
      // MANTENER background mode ON para evitar cortes si el usuario camina
      await _location.enableBackgroundMode(enable: true); // deja encendido

      // Solo reducir precisión y frecuencia para ahorrar batería
      await _location.changeSettings(
        accuracy: LocationAccuracy.low, // baja precisión
        distanceFilter: 20, // solo updates cada 20 metros
      );

      // Nota: NO desactivamos NativeLocationManager.disableBackgroundLocation()
      // para mantener tracking continuo sin "saltos" al reanudar
    } catch (e) {
      print('LocationService: Error pausing location tracking: $e');
    }
  }

  // Reanudar tracking de ubicación con configuración completa
  static Future<void> resumeLocationTracking() async {
    print('LocationService: Resuming location tracking...');
    try {
      // Re-enable native background location settings
      await NativeLocationManager.enableBackgroundLocation();

      // Re-enable background mode
      await _location.enableBackgroundMode(enable: true);
      // Restore high-accuracy settings
      await _location.changeSettings(
        accuracy: LocationAccuracy.navigation,
        interval: 1000, // 1 second
        distanceFilter: 5, // 5 meters
      );
    } catch (e) {
      print('LocationService: Error resuming location tracking: $e');
    }
  }

  // Parar tracking de ubicación completamente
  static Future<void> stopLocationTracking() async {
    if (_isStopping)
      return; // Evitar carreras si llaman stop dos veces seguidas
    _isStopping = true;

    try {
      print('LocationService: Stopping location tracking...');

      // Cancel subscription and wait for completion
      await _locationSubscription?.cancel();
      _locationSubscription = null;

      // Disable background mode and wait for completion
      await _location.enableBackgroundMode(enable: false);

      // Disable native background location and wait for completion
      await NativeLocationManager.disableBackgroundLocation();

      //Try-catch para final GPS status update
      if (_ref != null) {
        try {
          _ref!.read(gpsStatusProvider.notifier).state = GPSStatus.acquiring;
        } catch (e) {
          // Widget disposed, ignore and clear ref
          print(
              'LocationService: Final GPS status update failed (widget disposed): $e');
          _ref = null; // Clear ref to prevent further attempts
        }
      }

      // Reset state (no tocar el controller aquí: solo en dispose/reset)
      _isInitialized = false;
      _ref = null;

      print('LocationService: Stopped');
    } finally {
      _isStopping = false;
    }
  }

  // Cleanup completo - solo usar cuando la app se cierra completamente
  static Future<void> dispose() async {
    await stopLocationTracking();

    // Cerrar controller solo en cleanup final de la app
    if (_locationController != null && !_locationController!.isClosed) {
      _locationController!.close();
      _locationController = null;
    }
    _ref = null;
  }

  // Cleanup ligero - para usar entre corridas (NO cierra el controller)
  static Future<void> reset() async {
    await stopLocationTracking();
    // NO cerramos el controller - solo paramos el tracking
    // El controller permanece disponible para la próxima corrida
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

  // Check current permission status
  static Future<PermissionStatus> getPermissionStatus() async {
    return await _location.hasPermission();
  }

  // Check if we have "Always" permission using native iOS authorization status
  static Future<bool> hasAlwaysPermission() async {
    try {
      final status = await NativeLocationManager.authorizationStatus();
      return status == 'always';
    } catch (e) {
      print('LocationService: Error checking Always permission: $e');
      // Fallback to location plugin check
      final permission = await _location.hasPermission();
      return permission == PermissionStatus.granted;
    }
  }

  // Open app settings to allow user to upgrade from "When In Use" to "Always"
  static Future<bool> openAppSettings() async {
    try {
      return await ph.openAppSettings();
    } catch (e) {
      print('LocationService: Error opening app settings: $e');
      return false;
    }
  }

  // Check if location service is enabled and try to recover if not
  static Future<bool> checkAndRecoverLocationService() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        print(
            'LocationService: Location service disabled, attempting to re-enable...');
        serviceEnabled = await _location.requestService();
        if (serviceEnabled) {
          print('LocationService: Location service successfully re-enabled');
          return true;
        } else {
          print('LocationService: User declined to re-enable location service');
          return false;
        }
      }
      return true; // Service was already enabled
    } catch (e) {
      print('LocationService: Error checking/recovering location service: $e');
      return false;
    }
  }

  // Check if we need to show a message to user about location services
  static Future<bool> isLocationServiceAvailable() async {
    try {
      return await _location.serviceEnabled();
    } catch (e) {
      print(
          'LocationService: Error checking location service availability: $e');
      return false;
    }
  }

  // Get native iOS authorization status (distinguishes between Always and When In Use)
  static Future<String> getNativeAuthorizationStatus() async {
    try {
      return await NativeLocationManager.authorizationStatus();
    } catch (e) {
      print('LocationService: Error getting native authorization status: $e');
      return 'unknown';
    }
  }

  // Request Always permission explicitly (triggers second iOS prompt)
  static Future<void> requestAlwaysPermission() async {
    try {
      await NativeLocationManager.requestAlways();
    } catch (e) {
      print('LocationService: Error requesting Always permission: $e');
    }
  }
}
