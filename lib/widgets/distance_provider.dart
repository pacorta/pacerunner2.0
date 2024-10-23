import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'distance_unit_provider.dart';
import 'distance_unit_conversion.dart';

final distanceProvider = StateProvider<double>((ref) => 0.0);

//for KM or Miles
final formattedDistanceProvider = Provider<String>((ref) {
  final distanceKm = ref.watch(distanceProvider);
  final unit = ref.watch(distanceUnitProvider);

  if (unit == DistanceUnit.kilometers) {
    return '${distanceKm.toStringAsFixed(2)} km';
  } else {
    final distanceMiles = kilometersToMiles(distanceKm);
    return '${distanceMiles.toStringAsFixed(2)} mi';
  }
});
