import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'distance_unit_provider.dart';
import 'distance_unit_conversion.dart';

final speedProvider = StateProvider<double>((ref) => 0.0);

final formattedSpeedProvider = Provider<String>((ref) {
  final speedKm = ref.watch(speedProvider);
  final unit = ref.watch(distanceUnitProvider);

  if (unit == DistanceUnit.kilometers) {
    return '${speedKm.toStringAsFixed(2)} kmh';
  } else {
    final speedMiles = kilometersToMiles(speedKm);
    return '${speedMiles.toStringAsFixed(2)} mph';
  }
});
