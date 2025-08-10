import 'package:flutter/foundation.dart';

// Parseamos un pace string como "7:08/km" o "7:08/mi" a total de segundos por unidad.
// Devolvemos 0.0 si el string está vacío, "---", o no se puede parsear.
double parsePaceStringToSeconds(String paceString) {
  if (paceString.isEmpty || paceString == '---') return 0.0;

  try {
    // Mantenemos solo la parte de tiempo antes de la '/'
    final timePart = paceString.split('/').first.trim();

    // Soportamos formatos "m:ss" o "mm:ss"
    final parts = timePart.split(':');
    if (parts.length != 2) return 0.0;

    final minutes = int.tryParse(parts[0].trim()) ?? 0;
    final seconds = int.tryParse(parts[1].trim()) ?? 0;
    return (minutes * 60 + seconds).toDouble();
  } catch (e) {
    if (kDebugMode) {
      // Best-effort parsing; swallow errors in production
      // ignore: avoid_print
      print('parsePaceStringToSeconds: failed to parse "$paceString" → $e');
    }
    return 0.0;
  }
}
