// Target providers for pace prediction
// These providers store the user's target distance and time for pace predictions

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'custom_distance_provider.dart';
import 'custom_pace_provider.dart';
import 'distance_unit_provider.dart';

// Target distance provider (uses custom distance if set, otherwise null)
final targetDistanceProvider = Provider<double?>((ref) {
  return ref.watch(customDistanceProvider);
});

// Target time provider (calculated from custom pace and target distance)
final targetTimeProvider = Provider<double?>((ref) {
  final targetDistance = ref.watch(targetDistanceProvider);
  final customPace = ref.watch(customPaceProvider);

  print('TARGET PROVIDERS DEBUG:');
  print('  Target distance: $targetDistance');
  print('  Custom pace: $customPace sec/unit');

  if (targetDistance == null || customPace == null) {
    print('  Result: null (missing data)');
    return null;
  }

  // Calculate target time based on pace and distance
  // customPace is already in the correct unit (seconds/km or seconds/mi)
  // based on the distance unit selected by the user
  final result = targetDistance * customPace;
  print('  Calculated target time: $result seconds');
  return result;
});
