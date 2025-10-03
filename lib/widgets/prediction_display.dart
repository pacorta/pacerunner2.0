import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'projected_finish_provider.dart';
import 'goal_progress_provider.dart';
import 'distance_provider.dart';
import 'target_providers.dart';
import 'distance_unit_provider.dart';
import 'distance_unit_conversion.dart';

class PredictionDisplay extends ConsumerWidget {
  const PredictionDisplay({super.key});

  // Helper function to determine text color
  // - Distance-only goal: always white (no time comparison)
  // - Normal running: white when on/under target, red when over
  // - Finalized (after reaching target distance in complex goal):
  //   green when under-or-equal target time, red when over
  Color _getProjectionColor(
    Map<String, String> prediction, {
    required bool isFinalized,
    required bool hasTargetTime,
  }) {
    // For distance-only goals, always show white
    if (!hasTargetTime) {
      return Colors.white;
    }

    final difference = prediction['difference'];
    if (difference == null || difference == '0') {
      return isFinalized ? Colors.green : Colors.white;
    }

    final diffValue = double.tryParse(difference);
    if (diffValue == null) {
      return isFinalized ? Colors.green : Colors.white;
    }

    if (isFinalized) {
      // At finish distance: green if under or equal, else red
      return diffValue <= 0 ? Colors.green : Colors.red;
    }

    // During run: red when behind, white otherwise
    return diffValue > 0 ? Colors.red : Colors.white;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prediction = ref.watch(projectedFinishProvider);
    final firstReachTimeSecs = ref.watch(firstReachTargetTimeSecondsProvider);
    final currentDistanceKm = ref.watch(distanceProvider);
    final targetDistance = ref.watch(targetDistanceProvider);
    final targetTime = ref.watch(targetTimeProvider);
    final unit = ref.watch(distanceUnitProvider);

    bool isFinalized = false;
    bool hasTargetTime = targetTime != null;

    if (hasTargetTime && firstReachTimeSecs != null && targetDistance != null) {
      double targetDistanceKm = unit == DistanceUnit.miles
          ? milesToKilometers(targetDistance)
          : targetDistance;
      isFinalized = currentDistanceKm >= targetDistanceKm;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Projected Time
          Text(
            isFinalized ? 'Finish time' : 'Projected finish time',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),

          Text(
            prediction['projectedTime'] ?? 'Keep running...',
            style: TextStyle(
              color: _getProjectionColor(prediction,
                  isFinalized: isFinalized, hasTargetTime: hasTargetTime),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),

          /*
          // Status Message -- just in case.
          Text(
            prediction['status'] ?? 'Starting...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          */
        ],
      ),
    );
  }
}
