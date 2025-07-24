//This metric is only used to display to the user if needed.
//  To find the metric that makes the paceBar move, go to widgets/current_pace_in_seconds_provider.dart

//Current Pace: Calculates the time it takes to cover a specific distance.
//              Useful for runners to monitor if they are keeping a consistent pace.
//Current Pace = Time / Distance

//Here we are calculating the "average pace" every 4 seconds and returning a string with this information.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pausable_timer_provider.dart'; // Nuevo import (antes era elapsed_time_provider.dart)
import 'distance_provider.dart';
import 'distance_unit_provider.dart';
import 'distance_unit_conversion.dart';

double startWindowElapsedSeconds = 0.0;
double startWindowDistanceKm = 0.0;
String lastValidPace = "---";

void resetCurrentPaceProvider() {
  startWindowElapsedSeconds = 0.0;
  startWindowDistanceKm = 0.0;
  lastValidPace = "---";
}

final currentPaceProvider = Provider<String>((ref) {
  final currentElapsedSeconds = ref.watch(elapsedTimeInSecondsProvider);
  final currentDistanceKm = ref.watch(distanceProvider);
  final unit = ref.watch(distanceUnitProvider);

  // Check if the 5-second window has passed
  if (currentElapsedSeconds - startWindowElapsedSeconds >= 4) {
    // Calculate the time and distance differences over the 4-second interval
    final timeDifference = currentElapsedSeconds - startWindowElapsedSeconds;
    final distanceDifference = currentDistanceKm - startWindowDistanceKm;

    //print('Time Difference: $timeDifference');
    //print('Distance Difference: $distanceDifference');

    // Update the start of the window for the next interval
    startWindowElapsedSeconds = currentElapsedSeconds;
    startWindowDistanceKm = currentDistanceKm;

    if (distanceDifference > 0 && timeDifference > 0) {
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

      lastValidPace =
          '$minutes:${seconds.toString().padLeft(2, '0')}/${unit == DistanceUnit.kilometers ? 'km' : 'mi'}';

      print('Current Pace String: $lastValidPace');
    }
  }

  // Return the last valid pace, or "---" if no valid pace has been calculated yet
  return lastValidPace;
});
