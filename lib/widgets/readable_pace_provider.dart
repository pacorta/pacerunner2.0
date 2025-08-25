import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'distance_unit_provider.dart';

// Provider para almacenar el pace en formato legible
final readablePaceProvider = StateProvider<String>((ref) => '');

// Función para formatear el pace en formato legible
String formatPaceAsReadable(
    double distance, double timeInMinutes, DistanceUnit unit) {
  final unitLabel = unit == DistanceUnit.kilometers ? 'km' : 'miles';

  // Formatear el tiempo en formato "X:XX hrs" o "XX min"
  String timeFormatted;
  if (timeInMinutes >= 60) {
    final hours = timeInMinutes ~/ 60;
    final minutes = (timeInMinutes % 60).toInt();
    timeFormatted = '${hours}:${minutes.toString().padLeft(2, '0')} hrs';
  } else {
    timeFormatted = '${timeInMinutes.toInt()} min';
  }

  // Formatear la distancia con un decimal
  final distanceFormatted = distance.toStringAsFixed(1);

  return '$distanceFormatted $unitLabel under $timeFormatted';
}
