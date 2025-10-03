//PROJECTED FINISH TIME: Calculates projected finish time based on current average pace actual del usuario.
//                      Shows user: "At current pace, you'll finish in X time"
//                      Compares against target to show if ahead/behind goal

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'distance_provider.dart';
import 'distance_unit_provider.dart';
import 'target_providers.dart';
import 'stable_average_pace_provider.dart';
import 'package:pacerunner/utils/pace_utils.dart';
import 'goal_progress_provider.dart';
import 'distance_unit_conversion.dart';

// Provider that calculates projected finish time and status
final projectedFinishProvider = Provider<Map<String, String>>((ref) {
  final currentDistance = ref.watch(distanceProvider); // km
  final targetDistance = ref.watch(targetDistanceProvider);
  final targetTime = ref.watch(targetTimeProvider);
  final unit = ref.watch(distanceUnitProvider);
  final stablePaceString = ref.watch(stableAveragePaceProvider);
  final firstReachTimeSecs = ref.watch(firstReachTargetTimeSecondsProvider);

  // Return empty if no target distance set or insufficient data
  if (targetDistance == null || currentDistance < 0.05) {
    return {
      "projectedTime": "Calculating...",
      "status": "Starting...",
      "difference": "0",
    };
  }

  // Convert distances to consistent unit (use km internally)
  double targetDistanceKm = unit == DistanceUnit.miles
      ? milesToKilometers(targetDistance)
      : targetDistance;

  // Parse stable average pace (seconds per selected unit) and normalize to sec/km
  final paceSecondsPerUnit = parsePaceStringToSeconds(stablePaceString);
  final stableAveragePacePerKm = unit == DistanceUnit.miles
      ? paceSecondsPerUnit / milesToKilometers(1)
      : paceSecondsPerUnit;

  /*

  print('PROJECTION DEBUG:');
  print('  Target distance: $targetDistance ${unit.name}');
  print('  Target distance in km: $targetDistanceKm km');
  print('  Target time: $targetTime seconds');
  print('  Stable pace string: $stablePaceString');
  print('  Stable pace per km: $stableAveragePacePerKm sec/km');
  */

  // If the user has reached the goal distance (complex goal with time), freeze the
  // projection at the first time they hit the distance and compare vs target.
  if (targetTime != null &&
      firstReachTimeSecs != null &&
      currentDistance >= targetDistanceKm) {
    final projectedTotalSeconds = firstReachTimeSecs;

    // Format time as Xm Ys or Hh Mm Ss
    String formattedProjectedTime;
    final hours = (projectedTotalSeconds / 3600).floor();
    final minutes = ((projectedTotalSeconds % 3600) / 60).floor();
    final seconds = (projectedTotalSeconds % 60).floor();

    if (hours > 0) {
      formattedProjectedTime = "${hours}h ${minutes}m ${seconds}s";
    } else {
      formattedProjectedTime = "${minutes}m ${seconds}s";
    }

    final difference = projectedTotalSeconds - targetTime;

    return {
      "projectedTime": formattedProjectedTime,
      "status": "Finalized",
      "difference": difference.toString(),
    };
  }

  // If stable pace is not available yet, return calculating
  if (stableAveragePacePerKm == 0.0) {
    return {
      "projectedTime": "Calculating...",
      "status": "Starting...",
      "difference": "0",
    };
  }

  // Project total finish time (distance in km × pace in sec/km)
  final projectedTotalSeconds = targetDistanceKm * stableAveragePacePerKm;
  //print('  Projected total seconds: $projectedTotalSeconds');

  // Format projected time
  String formattedProjectedTime;
  final hours = (projectedTotalSeconds / 3600).floor();
  final minutes = ((projectedTotalSeconds % 3600) / 60).floor();
  final seconds = (projectedTotalSeconds % 60).floor();

  if (hours > 0) {
    formattedProjectedTime = "${hours}h ${minutes}m ${seconds}s";
  } else {
    formattedProjectedTime = "${minutes}m ${seconds}s";
  }

  // If no target time, just return the projection without status/difference
  if (targetTime == null) {
    return {
      "projectedTime": formattedProjectedTime,
      "status": "Distance-only goal",
      "difference": "0",
    };
  }

  // Calculate difference from target (only when target time exists)
  final difference = projectedTotalSeconds - targetTime;
  final diffMinutes = (difference.abs() / 60).floor();
  final diffSeconds = (difference.abs() % 60).floor();

  String status;
  if (difference > 30) {
    // Running slower than target
    status =
        "You're ${diffMinutes}:${diffSeconds.toString().padLeft(2, '0')} slow - speed up";
  } else if (difference < -30) {
    // Running faster than target
    status =
        "You're ${diffMinutes}:${diffSeconds.toString().padLeft(2, '0')} fast - you can relax";
  } else {
    // Right on target
    status = "Perfect! - keep this pace";
  }

  return {
    "projectedTime": formattedProjectedTime,
    "status": status,
    "difference": difference.toString(),
  };
});

// Helper provider to format target time nicely
final formattedTargetTimeProvider = Provider<String>((ref) {
  final targetTime = ref.watch(targetTimeProvider);
  if (targetTime == null) return "No target";

  final hours = (targetTime / 3600).floor();
  final minutes = ((targetTime % 3600) / 60).floor();
  final seconds = (targetTime % 60).floor();

  if (hours > 0) {
    return "${hours}h ${minutes}m ${seconds}s";
  } else {
    return "${minutes}m ${seconds}s";
  }
});

// Reset function for prediction providers
void resetPredictionProviders(WidgetRef ref) {
  // Force refresh of computed providers (they auto-refresh anyway)
  print('Prediction providers will auto-refresh from dependencies');
}
