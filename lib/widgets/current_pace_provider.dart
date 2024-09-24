//Current Pace: Calculates the time it takes to cover a specific distance.
//              Useful for runners to monitor if they are keeping a consistent pace.
//Current Pace = Time / Distance

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'elapsed_time_provider.dart';
import 'distance_provider.dart';
import 'unit_preference_provider.dart';
import 'distance_unit_conversion.dart';

double startWindowElapsedSeconds = 0.0;
double startWindowDistanceKm = 0.0;

final currentPaceProvider = Provider<String>((ref) {
  final currentElapsedSeconds = ref.watch(elapsedTimeProviderInSeconds);
  final currentDistanceKm = ref.watch(distanceProvider);
  final unit = ref.watch(distanceUnitProvider);

  // Check if the 3-second window has passed
  if (currentElapsedSeconds - startWindowElapsedSeconds >= 0.5) {
    // Calculate the time and distance differences over the 3-second interval
    final timeDifference = currentElapsedSeconds - startWindowElapsedSeconds;
    final distanceDifference = currentDistanceKm - startWindowDistanceKm;

    print('Time Difference: $timeDifference');
    print('Distance Difference: $distanceDifference');

    // Update the start of the window for the next interval
    startWindowElapsedSeconds = currentElapsedSeconds;
    startWindowDistanceKm = currentDistanceKm;

    if (distanceDifference <= 0 || timeDifference <= 0) {
      return "---";
    }

    // Calculate the pace
    double paceInSeconds;
    if (unit == DistanceUnit.kilometers) {
      paceInSeconds = timeDifference / distanceDifference;
    } else {
      final distanceMiles = kilometersToMiles(distanceDifference);
      paceInSeconds = timeDifference / distanceMiles;
    }

    // Convert to minutes and format
    final minutes = (paceInSeconds / 60).floor();
    final seconds = (paceInSeconds % 60).round();

    final currentPaceString =
        '$minutes:${seconds.toString().padLeft(2, '0')}/${unit == DistanceUnit.kilometers ? 'km' : 'mi'}';

    print('Current Pace String: $currentPaceString');

    return currentPaceString;
  }

  // If 3 seconds haven't passed, maintain the previous pace display
  return "---";
});
