import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
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

// Debug flag: forzar señal debil en modo debug (para probar UI)
const bool kForceWeakGPSForDebug =
    false; // false para produccion, true para debug.

// Helper function para determinar el estado basado en accuracy
GPSStatus determineGPSStatus(double? accuracy) {
  // En debug, si el flag está activo, fuerza "weak"
  if (kDebugMode && kForceWeakGPSForDebug) {
    return GPSStatus.weak;
  }
  // Considerar null como weak: ya hay fix (coordenadas) pero sin precisión reportada
  if (accuracy == null) {
    return GPSStatus.weak;
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
