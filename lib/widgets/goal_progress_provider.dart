import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stores the elapsed time string when the target distance is first reached
final firstReachTargetTimeStringProvider =
    StateProvider<String?>((ref) => null);

// Stores the elapsed time in seconds when the target distance is first reached
final firstReachTargetTimeSecondsProvider =
    StateProvider<double?>((ref) => null);

// Stores whether the user had an active distance+time goal during the run
final hadDistanceTimeGoalProvider = StateProvider<bool>((ref) => false);

// Stores whether the user had a distance-only goal during the run
final hadDistanceOnlyGoalProvider = StateProvider<bool>((ref) => false);

// Stores whether the user had a time-only goal during the run
final hadTimeOnlyGoalProvider = StateProvider<bool>((ref) => false);

// Helper to clear all goal progress state
void clearGoalProgressProviders(WidgetRef ref) {
  ref.read(firstReachTargetTimeStringProvider.notifier).state = null;
  ref.read(firstReachTargetTimeSecondsProvider.notifier).state = null;
  ref.read(hadDistanceTimeGoalProvider.notifier).state = false;
  ref.read(hadDistanceOnlyGoalProvider.notifier).state = false;
  ref.read(hadTimeOnlyGoalProvider.notifier).state = false;
}
