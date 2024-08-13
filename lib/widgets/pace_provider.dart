import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/widgets/distance_unit_conversion.dart';

import 'distance_provider.dart';
import 'unit_preference_provider.dart';
import 'elapsed_time_provider.dart';

final paceProvider = Provider<String>((ref) {
  final elapsedSeconds = ref.watch(elapsedTimeProviderInSeconds);
  final distanceKm = ref.watch(distanceProvider);
  final unit = ref.watch(distanceUnitProvider);

  if (distanceKm == 0 || elapsedSeconds == 0) return "0:00";

  double paceInSeconds;
  if (unit == DistanceUnit.kilometers) {
    paceInSeconds = elapsedSeconds / distanceKm;
  } else {
    final distanceMiles = kilometersToMiles(distanceKm);
    paceInSeconds = elapsedSeconds / distanceMiles;
  }

  final minutes = (paceInSeconds / 60).floor();
  final seconds = (paceInSeconds % 60).round();
  return '$minutes:${seconds.toString().padLeft(2, '0')}/${unit == DistanceUnit.kilometers ? 'km' : 'mi'}';
});
