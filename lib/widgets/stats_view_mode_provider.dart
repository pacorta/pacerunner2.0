import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StatsViewMode {
  currentWeek,
  last12Weeks,
}

/// Provider to manage the stats view mode selection
/// Always defaults to Last 12 Weeks (no persistence)
class StatsViewModeNotifier extends StateNotifier<StatsViewMode> {
  StatsViewModeNotifier() : super(StatsViewMode.last12Weeks);

  void setMode(StatsViewMode mode) {
    state = mode;
  }

  void toggle() {
    state = state == StatsViewMode.currentWeek
        ? StatsViewMode.last12Weeks
        : StatsViewMode.currentWeek;
  }
}

final statsViewModeProvider =
    StateNotifierProvider<StatsViewModeNotifier, StatsViewMode>(
  (ref) => StatsViewModeNotifier(),
);
