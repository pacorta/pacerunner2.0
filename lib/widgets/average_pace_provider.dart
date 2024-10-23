//AVERAGE PACE: Cauclates the time it takes to cover the distance since the beggining of the run.
//              Average Pace = Time / Distance
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'elapsed_time_provider.dart'; //1 √
import 'distance_provider.dart'; //2 √
import 'distance_unit_provider.dart'; //3 √
import 'distance_unit_conversion.dart'; //4 √

final averagePaceProvider = Provider<String>((ref) {
  final elapsedSeconds = ref.watch(elapsedTimeProviderInSeconds); //1
  final distanceKm = ref.watch(distanceProvider); //2
  final unit = ref.watch(distanceUnitProvider); //3

  // Add debug prints for the intermediate values
  print('Elapsed Seconds: $elapsedSeconds'); //√
  print('Distance in Km: $distanceKm'); //√
  print('Selected Unit: $unit'); //√

  if (distanceKm == 0 || elapsedSeconds == 0 || distanceKm < 0.0050) {
    return "---";
  }

  double paceInSeconds;

  if (unit == DistanceUnit.kilometers) {
    paceInSeconds = elapsedSeconds / distanceKm;
  } else {
    final distanceMiles = kilometersToMiles(distanceKm);
    paceInSeconds = elapsedSeconds / distanceMiles;
    print('Selected Unit: $unit'); //√
    print('Distance in Miles: $distanceMiles');
  }

  print('Pace in Seconds (elapsed seconds/distanceKm): $paceInSeconds'); //√

  final minutes = (paceInSeconds / 60).floor();
  final seconds = (paceInSeconds % 60).round();

  final averagePace =
      '$minutes:${seconds.toString().padLeft(2, '0')}/${unit == DistanceUnit.kilometers ? 'km' : 'mi'}';

  print('Average Pace: $averagePace');

  return averagePace;
});
