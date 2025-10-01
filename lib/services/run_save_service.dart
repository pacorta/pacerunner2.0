import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/distance_unit_provider.dart';
import '../widgets/target_providers.dart';
import '../widgets/time_goal_provider.dart';
import '../widgets/goal_progress_provider.dart';

class RunSaveService {
  static Map<String, dynamic> buildRunData({
    required WidgetRef ref,
    required double distance,
    required String distanceUnitString,
    required String finalTime,
    required String finalPace,
    DateTime? runStartTime,
  }) {
    final hasDistanceTimeGoal = ref.read(hadDistanceTimeGoalProvider);
    final hasDistanceOnlyGoal = ref.read(hadDistanceOnlyGoalProvider);
    final hasTimeOnlyGoal = ref.read(hadTimeOnlyGoalProvider);
    final firstReachTimeSecs = ref.read(firstReachTargetTimeSecondsProvider);
    final targetTimeSecs = ref.read(targetTimeProvider);
    final targetDistance = ref.read(targetDistanceProvider);
    final unit = ref.read(distanceUnitProvider);

    bool goalAchieved = false;
    int? goalCompletionTimeSeconds;
    int? totalRunTimeSeconds;

    // Parse total run duration from final time string (hh:mm:ss)
    final totalParts = finalTime.split(':');
    if (totalParts.length == 3) {
      totalRunTimeSeconds = (int.tryParse(totalParts[0]) ?? 0) * 3600 +
          (int.tryParse(totalParts[1]) ?? 0) * 60 +
          (int.tryParse(totalParts[2]) ?? 0);
    }

    // Epsilon tolerance to absorb rounding/timing edges
    final double eps = unit == DistanceUnit.kilometers ? 0.02 : 0.01;
    final bool reachedByDistance =
        targetDistance != null ? (distance + eps >= targetDistance) : false;

    // Prefer the precise first reach time; if missing but distance reached,
    // fall back to total run time seconds as the reach time.
    double? reachTimeSecs = firstReachTimeSecs;
    if (reachTimeSecs == null &&
        reachedByDistance &&
        totalRunTimeSeconds != null) {
      reachTimeSecs = totalRunTimeSeconds.toDouble();
    }

    if (hasDistanceTimeGoal &&
        targetDistance != null &&
        targetTimeSecs != null) {
      if (reachTimeSecs != null) {
        goalCompletionTimeSeconds = reachTimeSecs.round();
        goalAchieved = reachTimeSecs <= targetTimeSecs;
      }
    } else if (hasDistanceOnlyGoal && targetDistance != null) {
      final metByDistance = distance + eps >= targetDistance;
      goalAchieved = metByDistance;
      if (goalAchieved) {
        final fallback =
            (firstReachTimeSecs ?? totalRunTimeSeconds?.toDouble());
        if (fallback != null) {
          goalCompletionTimeSeconds = fallback.round();
        }
      }
    } else if (hasTimeOnlyGoal) {
      final targetSeconds = ref.read(timeOnlyGoalSecondsProvider);
      if (targetSeconds != null && totalRunTimeSeconds != null) {
        goalAchieved = totalRunTimeSeconds >= targetSeconds;
        if (goalAchieved) {
          // For time-only goals, the completion time is the target time itself
          goalCompletionTimeSeconds = targetSeconds.round();
        }
      }
    }

    final runData = <String, dynamic>{
      'distance': distance,
      'distanceUnitString': distanceUnitString,
      'time': finalTime,
      'averagePace': finalPace,
      'startTime': runStartTime?.toIso8601String(),
      'date': runStartTime?.toString().split(' ')[0],
      'timestamp': FieldValue.serverTimestamp(),
      // Goal achievement data
      'goalAchieved': goalAchieved,
      'goalCompletionTimeSeconds': goalCompletionTimeSeconds,
      'totalRunTimeSeconds': totalRunTimeSeconds,
    };

    return runData;
  }

  static Future<String?> saveRunData(Map<String, dynamic> runData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final docRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('runs')
        .add(runData);

    return docRef.id;
  }

  static Future<void> deleteRun(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('runs')
        .doc(docId)
        .delete();
  }
}
