//Current Pace: Calculates the time it takes to cover a specific distance.
//              Useful for runners to monitor if they are keeping a consistent pace.
//Current Pace = Time / Distance

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'elapsed_time_provider.dart';
import 'distance_provider.dart';
import 'unit_preference_provider.dart';
import 'distance_unit_conversion.dart';

/*
// Global variables to store previous values
double previousElapsedSeconds = 0.0;
double previousDistanceKm = 0.0;

final currentPaceProvider = Provider<String>((ref) {
  // Get the current elapsed time and distance
  final currentElapsedSeconds = ref.watch(elapsedTimeProviderInSeconds);
  final currentDistanceKm = ref.watch(distanceProvider);
  final unit = ref.watch(distanceUnitProvider);

  // Calculate the time and distance differences
  final timeDifference = currentElapsedSeconds - previousElapsedSeconds;
  final distanceDifference = currentDistanceKm - previousDistanceKm;

  print('Time Difference: $timeDifference');
  print('Distance Difference: $distanceDifference');

  // Update the previous values to the current ones for the next iteration
  previousElapsedSeconds = currentElapsedSeconds;
  previousDistanceKm = currentDistanceKm;

  // Check if the distance or time difference is too small to calculate pace
  if (distanceDifference <= 0 || timeDifference <= 0) {
    return "---";
  }

  // Calculate the current pace
  double paceInSeconds;
  if (unit == DistanceUnit.kilometers) {
    paceInSeconds = timeDifference / distanceDifference;
  } else {
    final distanceMiles = kilometersToMiles(distanceDifference);
    paceInSeconds = timeDifference / distanceMiles;
  }

  // Convert the pace from seconds to minutes and format it
  final minutes = (paceInSeconds / 60).floor();
  final seconds = (paceInSeconds % 60).round();

  final currentPaceString =
      '$minutes:${seconds.toString().padLeft(2, '0')}/${unit == DistanceUnit.kilometers ? 'km' : 'mi'}';

  // Print the current pace for debugging
  print('Current Pace String: $currentPaceString');

  return currentPaceString;
});

*/

// Variables to store the start of the 3-second window
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
