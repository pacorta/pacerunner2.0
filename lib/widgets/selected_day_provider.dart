import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track which day is selected in the week view
/// Index ranges from 0 (Monday) to 6 (Sunday)
/// Defaults to null (showing week totals, no specific day selected)
class SelectedDayNotifier extends StateNotifier<int?> {
  SelectedDayNotifier() : super(null); // Default to null (show week totals)

  void selectDay(int index) {
    if (index >= 0 && index < 7) {
      state = index;
    }
  }

  /// Clear selection to show week totals (used when entering week view)
  void clearSelection() {
    state = null;
  }
}

final selectedDayProvider =
    StateNotifierProvider<SelectedDayNotifier, int?>((ref) {
  return SelectedDayNotifier();
});
