//STABLE AVERAGE PACE: Simplified Strava-like implementation
//                    Time throttling + Data smoothing only
//                    More responsive, less over-engineered

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pausable_timer_provider.dart';
import 'distance_provider.dart';
import 'distance_unit_provider.dart';
import 'distance_unit_conversion.dart';

// Simplified global state
class _StablePaceState {
  static double _lastUpdateTime = 0.0;
  static List<double> _recentPaces = [];
  static String _lastDisplayedPace = "---";
  static const double _updateIntervalSeconds = 2.0;
  static const int _smoothingWindow = 3;

  static void reset() {
    _lastUpdateTime = 0.0;
    _recentPaces.clear();
    _lastDisplayedPace = "---";
  }
}

// Simplified stable average pace provider
final stableAveragePaceProvider = Provider<String>((ref) {
  final elapsedSeconds = ref.watch(elapsedTimeInSecondsProvider);
  final distanceKm = ref.watch(distanceProvider);
  final unit = ref.watch(distanceUnitProvider);

  // ESTRATEGIA 1: Time throttling (every 2 seconds)
  if (elapsedSeconds - _StablePaceState._lastUpdateTime <
      _StablePaceState._updateIntervalSeconds) {
    return _StablePaceState._lastDisplayedPace;
  }

  // Basic data validation
  if (distanceKm < 0.050 || elapsedSeconds < 10) {
    return "---";
  }

  // Calculate raw pace
  double paceInSeconds;
  if (unit == DistanceUnit.kilometers) {
    paceInSeconds = elapsedSeconds / distanceKm;
  } else {
    final distanceMiles = kilometersToMiles(distanceKm);
    paceInSeconds = elapsedSeconds / distanceMiles;
  }

  // ESTRATEGIA 2: Data smoothing (moving average)
  _StablePaceState._recentPaces.add(paceInSeconds);
  if (_StablePaceState._recentPaces.length >
      _StablePaceState._smoothingWindow) {
    _StablePaceState._recentPaces.removeAt(0);
  }

  // Use smoothed pace
  double smoothedPace = _StablePaceState._recentPaces.reduce((a, b) => a + b) /
      _StablePaceState._recentPaces.length;

  // Format and update
  final minutes = (smoothedPace / 60).floor();
  final seconds = (smoothedPace % 60).round();
  _StablePaceState._lastDisplayedPace =
      '$minutes:${seconds.toString().padLeft(2, '0')}/${unit == DistanceUnit.kilometers ? 'km' : 'mi'}';

  // Update tracking
  _StablePaceState._lastUpdateTime = elapsedSeconds;

  return _StablePaceState._lastDisplayedPace;
});

// Reset function
void resetStableAveragePace(WidgetRef ref) {
  _StablePaceState.reset();
}
