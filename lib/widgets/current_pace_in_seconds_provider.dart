//Current Pace: Calculates the time it takes to cover a specific distance.
//              Useful for runners to monitor if they are keeping a consistent pace.
//Current Pace = Time / Distance

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pausable_timer_provider.dart'; // Nuevo import (antes era elapsed_time_provider.dart)
import 'distance_provider.dart';
import 'distance_unit_provider.dart';
import 'distance_unit_conversion.dart';

double startWindowElapsedSeconds = 0.0;
double startWindowDistanceKm = 0.0;
double lastValidPaceInSeconds = 0.0; // Keep track of the last valid pace

void resetCurrentPaceInSecondsProvider() {
  startWindowElapsedSeconds = 0.0;
  startWindowDistanceKm = 0.0;
  lastValidPaceInSeconds = 0.0;
}

final currentPaceInSecondsProvider = Provider<double>((ref) {
  final currentElapsedSeconds = ref.watch(elapsedTimeInSecondsProvider);
  final currentDistanceKm = ref.watch(distanceProvider);
  final unit = ref.watch(distanceUnitProvider);

  // Check if the 4-second window has passed
  if (currentElapsedSeconds - startWindowElapsedSeconds >= 4.0) {
    // Calculate the time and distance differences over the 4-second interval
    final timeDifference = currentElapsedSeconds - startWindowElapsedSeconds;
    final distanceDifference = currentDistanceKm - startWindowDistanceKm;

    print('Time Difference: $timeDifference');
    print('Distance Difference: $distanceDifference');

    // Update the start of the window for the next interval
    startWindowElapsedSeconds = currentElapsedSeconds;
    startWindowDistanceKm = currentDistanceKm;

    if (distanceDifference <= 0 || timeDifference <= 0) {
      return lastValidPaceInSeconds; // Return the last valid pace
    }

    // Calculate pace in seconds per km or mile
    double paceInSeconds;
    if (unit == DistanceUnit.kilometers) {
      paceInSeconds = timeDifference / distanceDifference;
    } else {
      final distanceMiles = kilometersToMiles(distanceDifference);
      paceInSeconds = timeDifference / distanceMiles;
    }

    // Store the last valid pace
    lastValidPaceInSeconds = paceInSeconds;

    return paceInSeconds;
  }

  // If 4 seconds haven't passed, return the last valid pace
  return lastValidPaceInSeconds;
});
