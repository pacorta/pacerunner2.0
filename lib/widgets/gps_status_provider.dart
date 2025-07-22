import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// Estados posibles del GPS
enum GPSStatus {
  acquiring, // Buscando señal GPS inicial
  weak, // Accuracy > 50 metros (señal débil)
  good, // Accuracy 10-50 metros (señal buena)
  strong // Accuracy < 10 metros (señal excelente)
}

// Provider para el estado actual del GPS
final gpsStatusProvider =
    StateProvider<GPSStatus>((ref) => GPSStatus.acquiring);

// Helper function para determinar el estado basado en accuracy
GPSStatus determineGPSStatus(double? accuracy) {
  if (accuracy == null) {
    return GPSStatus.acquiring;
  }

  if (accuracy < 10.0) {
    return GPSStatus.strong;
  } else if (accuracy < 50.0) {
    return GPSStatus.good;
  } else {
    return GPSStatus.weak;
  }
}

// Helper function para obtener color basado en estado
Color getGPSStatusColor(GPSStatus status) {
  switch (status) {
    case GPSStatus.acquiring:
      return Colors.orange;
    case GPSStatus.weak:
      return Colors.red;
    case GPSStatus.good:
      return Colors.yellow[700]!;
    case GPSStatus.strong:
      return Colors.green;
  }
}
