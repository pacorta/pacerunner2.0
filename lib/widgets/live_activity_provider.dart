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

      // Build goal and predicted finish strings if available
      final targetDistance = _ref.read(targetDistanceProvider);
      final targetTimeFormatted = _ref.read(formattedTargetTimeProvider);
      String? goal;
      if (targetDistance != null) {
        goal =
            "${targetDistance.toStringAsFixed(1)} $distanceUnitString in $targetTimeFormatted";
      }
      final projection = _ref.read(projectedFinishProvider);
      String? predictedFinish = projection["projectedTime"];

      // Convert distance to proper unit for display
      double displayDistance = distance;
      if (distanceUnit == DistanceUnit.miles) {
        displayDistance = kilometersToMiles(distance);
      }

      final success = await LiveActivityService.updateRunningActivity(
        distance: displayDistance,
        distanceUnit: distanceUnitString,
        elapsedTime: elapsedTime,
        pace: pace,
        isRunning: isRunning,
        goal: goal,
        predictedFinish: predictedFinish,
      );

      if (!success) {
        print('Failed to update Live Activity');
      }
    } catch (e) {
      print('Error updating Live Activity: $e');
    }
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
