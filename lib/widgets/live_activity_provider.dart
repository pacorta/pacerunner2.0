import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/live_activity_service.dart';
import 'distance_provider.dart';
import 'distance_unit_provider.dart';
import 'distance_unit_as_string_provider.dart';
import 'distance_unit_conversion.dart';
import 'pausable_timer_provider.dart';
import 'stable_average_pace_provider.dart';
import 'run_state_provider.dart';
import 'projected_finish_provider.dart';
import 'target_providers.dart';
import 'time_difference_provider.dart';
import 'time_goal_provider.dart';
import 'custom_pace_provider.dart';

// Provider to manage Live Activity state
final liveActivityProvider =
    StateNotifierProvider<LiveActivityNotifier, bool>((ref) {
  return LiveActivityNotifier(ref);
});

class LiveActivityNotifier extends StateNotifier<bool> {
  final Ref _ref;
  bool _isActivityActive = false;

  LiveActivityNotifier(this._ref) : super(false) {
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to run state changes to start/stop live activity
    _ref.listen<RunState>(runStateProvider, (previous, next) {
      _handleRunStateChange(previous, next);
    });

    // Listen to distance changes to update live activity
    _ref.listen<double>(distanceProvider, (previous, next) {
      if (_isActivityActive && next != previous) {
        _updateLiveActivity();
      }
    });

    // Listen to timer changes to update live activity
    _ref.listen<Duration>(pausableTimerProvider, (previous, next) {
      if (_isActivityActive && next != previous) {
        _updateLiveActivity();
      }
    });

    // Listen to goal/prediction related providers so updates push through
    _ref.listen<Map<String, String>>(projectedFinishProvider, (previous, next) {
      if (_isActivityActive && next != previous) {
        _updateLiveActivity();
      }
    });
    _ref.listen<double?>(targetDistanceProvider, (previous, next) {
      if (_isActivityActive && next != previous) {
        _updateLiveActivity();
      }
    });
    _ref.listen<String>(formattedTargetTimeProvider, (previous, next) {
      if (_isActivityActive && next != previous) {
        _updateLiveActivity();
      }
    });
  }

  void _handleRunStateChange(RunState? previous, RunState next) async {
    switch (next) {
      case RunState.running:
        if (!_isActivityActive) {
          await _startLiveActivity();
        } else {
          _updateLiveActivity();
        }
        break;
      case RunState.paused:
        if (_isActivityActive) {
          _updateLiveActivity();
        }
        break;
      case RunState.finished:
        if (_isActivityActive) {
          await _endLiveActivity();
        }
        break;
      default:
        // Do nothing for other states
        break;
    }
  }

  Future<void> _startLiveActivity() async {
    try {
      // Check if Live Activities are available
      final isAvailable = await LiveActivityService.areActivitiesAvailable();
      if (!isAvailable) {
        print('Live Activities not available on this device');
        return;
      }

      final success = await LiveActivityService.startRunningActivity();
      if (success) {
        _isActivityActive = true;
        state = true;
        print('Live Activity started successfully');
        // Initial update with current data
        _updateLiveActivity();
      } else {
        print('Failed to start Live Activity');
      }
    } catch (e) {
      print('Error starting Live Activity: $e');
    }
  }

  Future<void> _updateLiveActivity() async {
    if (!_isActivityActive) return;

    try {
      // Get current running data
      final distance = _ref.read(distanceProvider);
      final distanceUnit = _ref.read(distanceUnitProvider);
      final distanceUnitString = _ref.read(formattedUnitString);
      final elapsedTime = _ref.read(formattedElapsedTimeProvider);
      final pace = _ref.read(stableAveragePaceProvider);
      final runState = _ref.read(runStateProvider);
      final isRunning = runState == RunState.running;

      // Goal typing and labels
      final targetDistance =
          _ref.read(targetDistanceProvider); // complex or distance-only
      final timeOnlySeconds =
          _ref.read(timeOnlyGoalSecondsProvider); // time-only
      final targetTimeFormatted =
          _ref.read(formattedTargetTimeProvider); // for complex

      String? goal;
      String? predictedFinish;
      int? differenceSeconds;

      // Progress fields
      double? progress;
      String? progressKind;
      String? progressLabel;

      // Convert distance to proper unit for display
      double displayDistance = distance;
      if (distanceUnit == DistanceUnit.miles) {
        displayDistance = kilometersToMiles(distance);
      }

      // Decide behavior based on goal type
      final hasComplex =
          targetDistance != null && _ref.read(customPaceProvider) != null;
      final hasDistanceOnly =
          targetDistance != null && _ref.read(customPaceProvider) == null;
      final hasTimeOnly = timeOnlySeconds != null;

      if (hasComplex) {
        // Distance + Time goal
        final double td = targetDistance;
        goal =
            "${td.toStringAsFixed(1)} $distanceUnitString under $targetTimeFormatted";
        final projection = _ref.read(projectedFinishProvider);
        predictedFinish = projection["projectedTime"];
        differenceSeconds = _ref.read(timeDifferenceSecondsProvider);

        // Progress based on distance
        if (td > 0) {
          progress = (displayDistance / td).clamp(0.0, 1.0);
          progressKind = "distance";
          progressLabel =
              "${displayDistance.toStringAsFixed(1)}/${td.toStringAsFixed(1)} $distanceUnitString";
        }
      } else if (hasDistanceOnly) {
        // Distance-only goal (now shows projection without time comparison)
        final double td = targetDistance;
        goal = "Run ${td.toStringAsFixed(1)} $distanceUnitString";

        // Show projected finish time based on current pace
        final projection = _ref.read(projectedFinishProvider);
        predictedFinish = projection["projectedTime"];
        differenceSeconds = null; // No time comparison for distance-only

        if (td > 0) {
          progress = (displayDistance / td).clamp(0.0, 1.0);
          progressKind = "distance";
          progressLabel =
              "${displayDistance.toStringAsFixed(1)}/${td.toStringAsFixed(1)} $distanceUnitString";
        }
      } else if (hasTimeOnly) {
        // Time-only goal
        final elapsedSeconds = _ref.read(elapsedTimeInSecondsProvider);
        final double tos = timeOnlySeconds;
        // Label for time-only goal
        goal = "${_formatSimpleTime(tos)} run";
        predictedFinish = null;
        differenceSeconds = null;

        if (tos > 0) {
          progress = (elapsedSeconds / tos).clamp(0.0, 1.0);
          progressKind = "time";
          final elapsedFmt = _ref.read(formattedElapsedTimeProvider);
          final targetFmt = _formatSimpleTime(tos);
          progressLabel = "$elapsedFmt/$targetFmt";
        }
      } else {
        // Quick run (no goal)
        goal = null;
        predictedFinish = null;
        differenceSeconds = null;
        progress = null;
        progressKind = null;
        progressLabel = null;
      }

      final success = await LiveActivityService.updateRunningActivity(
        distance: displayDistance,
        distanceUnit: distanceUnitString,
        elapsedTime: elapsedTime,
        pace: pace,
        isRunning: isRunning,
        goal: goal,
        predictedFinish: predictedFinish,
        differenceSeconds: differenceSeconds,
        progress: progress,
        progressKind: progressKind,
        progressLabel: progressLabel,
      );

      if (!success) {
        print('Failed to update Live Activity');
      }
    } catch (e) {
      print('Error updating Live Activity: $e');
    }
  }

  String _formatSimpleTime(double seconds) {
    final total = seconds.floor();
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final secs = total % 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    if (minutes > 0) {
      return secs > 0 && minutes < 5 ? '${minutes}m ${secs}s' : '${minutes}m';
    }
    return '${secs}s';
  }

  Future<void> _endLiveActivity() async {
    if (!_isActivityActive) return;

    try {
      // Final update before ending
      _updateLiveActivity();

      // Small delay to ensure final update is processed
      await Future.delayed(const Duration(milliseconds: 500));

      final success = await LiveActivityService.endRunningActivity();
      if (success) {
        _isActivityActive = false;
        state = false;
        print('Live Activity ended successfully');
      } else {
        print('Failed to end Live Activity');
      }
    } catch (e) {
      print('Error ending Live Activity: $e');
    }
  }

  // Manual controls (optional)
  Future<void> startActivity() async {
    if (!_isActivityActive) {
      await _startLiveActivity();
    }
  }

  Future<void> endActivity() async {
    if (_isActivityActive) {
      await _endLiveActivity();
    }
  }

  @override
  void dispose() {
    // End activity when provider is disposed
    if (_isActivityActive) {
      LiveActivityService.endRunningActivity();
    }
    super.dispose();
  }
}
