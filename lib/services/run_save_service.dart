import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  // ========== LOCAL BACKUP METHODS ==========

  /// Save run data locally as backup (in case Firestore fails or offline)
  static Future<void> saveLocalBackup(Map<String, dynamic> runData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing backups
      final backupsJson = prefs.getString('pending_runs') ?? '[]';
      final List<dynamic> backups = json.decode(backupsJson);

      // Add timestamp if not present (for ordering)
      final dataWithMeta = {
        ...runData,
        'localSaveTime': DateTime.now().toIso8601String(),
        'synced': false,
      };

      backups.add(dataWithMeta);

      // Save back
      await prefs.setString('pending_runs', json.encode(backups));

      // ignore: avoid_print
      print('RunSaveService: Local backup saved (${backups.length} pending)');
    } catch (e) {
      // ignore: avoid_print
      print('RunSaveService: Error saving local backup: $e');
    }
  }

  /// Get all pending runs that need to be synced
  static Future<List<Map<String, dynamic>>> getPendingRuns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupsJson = prefs.getString('pending_runs') ?? '[]';
      final List<dynamic> backups = json.decode(backupsJson);

      return backups
          .where((run) => run['synced'] != true)
          .map((run) => Map<String, dynamic>.from(run))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('RunSaveService: Error getting pending runs: $e');
      return [];
    }
  }

  /// Sync all pending runs to Firestore
  static Future<int> syncPendingRuns() async {
    try {
      final pending = await getPendingRuns();
      if (pending.isEmpty) return 0;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;

      int synced = 0;
      for (final runData in pending) {
        try {
          // Remove local metadata before saving
          final cleanData = Map<String, dynamic>.from(runData);
          cleanData.remove('localSaveTime');
          cleanData.remove('synced');

          // Save to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('runs')
              .add(cleanData);

          synced++;
          // ignore: avoid_print
          print('RunSaveService: Synced pending run $synced/${pending.length}');
        } catch (e) {
          // ignore: avoid_print
          print('RunSaveService: Failed to sync one run: $e');
          // Continue with next run
        }
      }

      // Clear synced runs
      if (synced > 0) {
        await _clearSyncedRuns(synced);
      }

      return synced;
    } catch (e) {
      // ignore: avoid_print
      print('RunSaveService: Error syncing pending runs: $e');
      return 0;
    }
  }

  /// Clear successfully synced runs from local storage
  static Future<void> _clearSyncedRuns(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupsJson = prefs.getString('pending_runs') ?? '[]';
      final List<dynamic> backups = json.decode(backupsJson);

      // Remove first N runs (oldest)
      final remaining = backups.skip(count).toList();

      await prefs.setString('pending_runs', json.encode(remaining));
      // ignore: avoid_print
      print(
          'RunSaveService: Cleared $count synced runs, ${remaining.length} remaining');
    } catch (e) {
      // ignore: avoid_print
      print('RunSaveService: Error clearing synced runs: $e');
    }
  }
}
