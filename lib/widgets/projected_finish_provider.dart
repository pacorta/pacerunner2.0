//PROJECTED FINISH TIME: Calculates projected finish time based on current average pace actual del usuario.
//                      Shows user: "At current pace, you'll finish in X time"
//                      Compares against target to show if ahead/behind goal

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'distance_provider.dart';
import 'distance_unit_provider.dart';
import 'target_providers.dart';
import 'stable_average_pace_provider.dart';

// Helper function to convert stable average pace string to seconds per km
double _parseStablePaceToSeconds(String paceString) {
  if (paceString == "---" || paceString.isEmpty) {
    return 0.0;
  }

  // Extract the time part (before the "/")
  final timePart = paceString.split('/')[0];
  final parts = timePart.split(':');

  if (parts.length == 2) {
    final minutes = int.tryParse(parts[0]) ?? 0;
    final seconds = int.tryParse(parts[1]) ?? 0;
    return (minutes * 60 + seconds).toDouble();
  }

  return 0.0;
}

// Provider that calculates projected finish time and status
final projectedFinishProvider = Provider<Map<String, String>>((ref) {
  final currentDistance = ref.watch(distanceProvider); // km
  final targetDistance = ref.watch(targetDistanceProvider);
  final targetTime = ref.watch(targetTimeProvider);
  final unit = ref.watch(distanceUnitProvider);
  final stablePaceString = ref.watch(stableAveragePaceProvider);

  // Return empty if no target set or insufficient data
  if (targetDistance == null || targetTime == null || currentDistance < 0.05) {
    return {
      "projectedTime": "Calculating...",
      "status": "Starting...",
      "difference": "0",
    };
  }

  // Convert distances to consistent unit (use km internally)
  double targetDistanceKm = targetDistance;
  if (unit == DistanceUnit.miles) {
    targetDistanceKm = targetDistance * 1.60934; // Convert miles to km
  }

  // Use stable average pace instead of direct calculation
  final stableAveragePacePerKm = _parseStablePaceToSeconds(stablePaceString);

  // If stable pace is not available yet, return calculating
  if (stableAveragePacePerKm == 0.0) {
    return {
      "projectedTime": "Calculating...",
      "status": "Starting...",
      "difference": "0",
    };
  }

  // Project total finish time
  final projectedTotalSeconds = targetDistanceKm * stableAveragePacePerKm;

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

  // Calculate difference from target
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
