import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track which week is selected in the 12-week view
/// Index ranges from 0 (oldest week) to 11 (most recent week)
/// Defaults to 11 (current week)
class SelectedWeekNotifier extends StateNotifier<int> {
  SelectedWeekNotifier() : super(11); // Default to most recent week

  void selectWeek(int index) {
    if (index >= 0 && index < 12) {
      state = index;
    }
  }

  /// Reset to most recent week (used when entering 12-week view)
  void resetToMostRecent() {
    state = 11;
  }
}

final selectedWeekProvider =
    StateNotifierProvider<SelectedWeekNotifier, int>((ref) {
  return SelectedWeekNotifier();
});
