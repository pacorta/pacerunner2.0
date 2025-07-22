import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'distance_provider.dart';
import 'tracking_provider.dart';
import 'speed_provider.dart';
import 'gps_status_provider.dart';
import 'dart:math' as math;

class Map extends ConsumerStatefulWidget {
  const Map({super.key});

  @override
  ConsumerState<Map> createState() => _MapState(); //riverpod "consumer"
}

class _MapState extends ConsumerState<Map> {
  GoogleMapController? mapController;
  final Location location = Location(); //unmutable
  LatLng _currentPosition = const LatLng(0, 0);
  bool _locationObtained = false;

//polyline points
  PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> polylineCoordinates = []; //map FS

//speed
  double _currentSpeed =
      0.0; //                                                           state
  double getSpeedInMph() {
    return _currentSpeed * 2.23694;
  }

//Calculate Distance Travelled
  final List<LocationData> _locations = [];
  //double _totalDistance = 0.0; //#istrackingchanges: Own file: distance_provider.dart
  //bool _isTracking = false;     #istrackingchanges: This one we move it to its own file, tracking_provider.dart

//subscription to check the gathering of data as on/off
  StreamSubscription<LocationData>?
      locationSubscription; // From the async library

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    //_startTimer();
  }

//December 3, 2024: all cleanup operations in 1 function
  void _cleanupLocationTracking() {
    locationSubscription?.cancel(); // Stops receiving location updates
    _locations.clear(); // Clears stored location history
    polylineCoordinates.clear(); // Clears the route line on the map
  }

  @override
  void dispose() {
    locationSubscription?.cancel(); // Cancel the subscription
    mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    //print("_onMapCreated called");
    mapController = controller;
  }

  void _updatePolyline(LatLng newPoint) {
    if (mounted) {
      setState(() {
        polylineCoordinates.add(newPoint);
      });
    }
  }

  void _getCurrentLocation() async {
    //to implement riverpod
    //print("_getCurrentLocation called");
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    //print("Service enabled: $serviceEnabled");
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      //print("Service enabled after request: $serviceEnabled");
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    //print("Permission granted: $permissionGranted");
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      //print("Permission granted after request: $permissionGranted");
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    try {
      final locationData = await location.getLocation();
      //print("Location data: ${locationData.latitude}, ${locationData.longitude}"); // Log entry
      //print("Accuracy: ${locationData.accuracy}, Altitude: ${locationData.altitude}"); // More details
      //print('Current speed: ${locationData.speed} m/s');

      //Actualizar GPS status basado en accuracy
      final gpsStatus = determineGPSStatus(locationData.accuracy);
      ref.read(gpsStatusProvider.notifier).state = gpsStatus;

      if (mounted) {
        setState(() {
          _currentPosition =
              LatLng(locationData.latitude!, locationData.longitude!);
          _locationObtained = true;
          polylineCoordinates.add(_currentPosition);
        });
      }
    } catch (e) {
      //print("Error getting location: $e"); // Log entry
    }

    // Set up a listener for location changes (with location subscription)
    locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      //print("Location updated: ${currentLocation.latitude}, ${currentLocation.longitude}, Speed: ${currentLocation.speed} m/s"); // Log entry

      //december 3, 2024: added this check to prevent memory leak
      if (!mounted) return;

      //Actualizar GPS status en cada cambio de ubicación
      final gpsStatus = determineGPSStatus(currentLocation.accuracy);
      ref.read(gpsStatusProvider.notifier).state = gpsStatus;

      final isTracking = ref.read(trackingProvider);
      if (!isTracking) {
        _cleanupLocationTracking();
        return;
      }

      setState(() {
        _currentPosition =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
        _currentSpeed = currentLocation.speed!;
        double speedInMph =
            getSpeedInMph(); //notifying convertion of mps to mph of the _currentSpeed
        ref.read(speedProvider.notifier).state =
            speedInMph; // notifier for riverpod
        //Distance notifiers
        if (ref.read(trackingProvider)) {
          if (_locations.isNotEmpty) {
            double additionalDistance = _calculateDistance(
              _locations.last.latitude!,
              _locations.last.longitude!,
              currentLocation.latitude!,
              currentLocation.longitude!,
            );
            ref.read(distanceProvider.notifier).state += additionalDistance;
          }
          _locations.add(currentLocation);
        }

        //_locations.add(currentLocation);
        //ref.read(distanceProvider.notifier).state = _totalDistance;
        //polylines
        LatLng newPoint =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
        _updatePolyline(newPoint);
        location.changeSettings(accuracy: LocationAccuracy.high);
        //checking if mapcontroller is initialized before use
        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentPosition, zoom: 20),
            ),
          );
        }
      });
    });
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // PI / 180
    var c = math.cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R * asin(sqrt(a))
  }

//calculate distance END
  @override
  Widget build(BuildContext context) {
    //december 3, 2024: added this listener to clean up the location tracking when the user is not tracking
    ref.listen(trackingProvider, (previous, next) {
      if (!next) {
        _cleanupLocationTracking();
      }
    });
    return MaterialApp(
      home: Scaffold(
        body: _locationObtained
            ? Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    mapType: MapType.terrain,
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
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
