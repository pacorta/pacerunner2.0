import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class Map extends StatefulWidget {
  const Map({super.key});

  @override
  State<Map> createState() => _MapState();
}

class _MapState extends State<Map> {
  GoogleMapController?
      mapController; //will be declared later //changed to (?) nullable from "late"
  final Location location = Location(); //unmutable
  LatLng _currentPosition = const LatLng(0, 0);
  bool _locationObtained = false;
//speed
  double _currentSpeed = 0.0;
//polyline points
  PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> polylineCoordinates = [];
//timer
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsedTime = '00:00:00';
//subscription to check the gathering of data as on/off
  StreamSubscription<LocationData>?
      locationSubscription; // From the async library

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startTimer();
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

  Future<void> _getCurrentLocation() async {
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
      if (mounted) {
        setState(() {
          _currentPosition =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _currentSpeed = currentLocation.speed!;
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
      }
    });
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = _formatDuration(_stopwatch.elapsed);
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _endRun() {
    _stopwatch.stop();
    _timer?.cancel();
    // Here you can add code to save the run data, show a summary, etc.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run Completed'),
        content: Text('Your run lasted $_elapsedTime'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to home screen
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title:
              Text('Speed: $_currentSpeed m/s \n Elapsed Time: $_elapsedTime'),
        ),
        body: _locationObtained
            ? Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    mapType: MapType.satellite,
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
                        color: const Color.fromARGB(255, 243, 103, 33),
                        width: 5,
                      ),
                    },
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 210, 110, 57),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      onPressed: _endRun,
                      child: const Text(
                        'STOP',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
