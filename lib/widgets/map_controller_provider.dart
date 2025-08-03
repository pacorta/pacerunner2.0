import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:typed_data';
import 'dart:math' as math;

// provider para el GoogleMapController
final mapControllerProvider =
    StateProvider<GoogleMapController?>((ref) => null);

// provider para las ubicaciones (para calcular bounds)
final locationsProvider = StateProvider<List<LocationData>>((ref) => []);

// Provider para polyline coordinates (para mostrar en el screenshot)
final polylineCoordinatesProvider = StateProvider<List<LatLng>>((ref) => []);

// helper: para calcular bounds de la ruta
LatLngBounds calculateRouteBounds(List<LocationData> locations) {
  if (locations.isEmpty) {
    return LatLngBounds(
      southwest: LatLng(0, 0),
      northeast: LatLng(0, 0),
    );
  }

  double minLat = locations.first.latitude!;
  double maxLat = locations.first.latitude!;
  double minLng = locations.first.longitude!;
  double maxLng = locations.first.longitude!;

  for (var location in locations) {
    minLat = math.min(minLat, location.latitude!);
    maxLat = math.max(maxLat, location.latitude!);
    minLng = math.min(minLng, location.longitude!);
    maxLng = math.max(maxLng, location.longitude!);
  }

  // Reducir de 0.1 a 0.05 = 5%
  double latPadding = (maxLat - minLat) * 0.05;
  double lngPadding = (maxLng - minLng) * 0.05;

  return LatLngBounds(
    southwest: LatLng(minLat - latPadding, minLng - lngPadding),
    northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
  );
}

// helper: para capturar screenshot del mapa
Future<Uint8List?> captureMapScreenshot(
  GoogleMapController? mapController,
  List<LocationData> locations,
) async {
  if (mapController == null || locations.isEmpty) {
    print('MapScreenshot: No controller or locations available');
    return null;
  }

  try {
    print('MapScreenshot: Capturing screenshot...');

    // calcular bounds y ajustar camara
    LatLngBounds bounds = calculateRouteBounds(locations);

    await mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50), // Reducir de 100 a 50 pixels
    );

    // esperar un momento para que se ajuste la camara
    await Future.delayed(Duration(milliseconds: 800));

    // tomar screenshot
    Uint8List? screenshot = await mapController.takeSnapshot();

    print('MapScreenshot: Screenshot captured successfully');
    return screenshot;
  } catch (e) {
    print('MapScreenshot: Error capturing screenshot: $e');
    return null;
  }
}
