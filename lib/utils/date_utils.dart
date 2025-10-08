/// Date and week formatting utilities for the running app
/// Reuses month and day name constants consistently across the app

const List<String> monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

const List<String> dayNamesShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

const List<String> dayNamesFull = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];

/// Formats a week range as "MMM DD - MMM DD, YYYY" or "This week"
/// Example: "Sep 29 - Oct 5, 2025" or "This week"
String formatWeekRange(DateTime startOfWeek, {DateTime? referenceDate}) {
  final now = referenceDate ?? DateTime.now();
  final currentWeekStart = _getStartOfWeek(now);

  // Check if this is the current week
  if (startOfWeek.year == currentWeekStart.year &&
      startOfWeek.month == currentWeekStart.month &&
      startOfWeek.day == currentWeekStart.day) {
    return 'This week';
  }

  // Calculate end of week (Sunday)
  final endOfWeek = startOfWeek.add(const Duration(days: 6));

  // Format: "Sep 29 - Oct 5, 2025"
  final startMonth = monthAbbreviations[startOfWeek.month - 1];
  final endMonth = monthAbbreviations[endOfWeek.month - 1];

  // If same month, show: "Aug 18 - Aug 24, 2025"
  if (startOfWeek.month == endOfWeek.month &&
      startOfWeek.year == endOfWeek.year) {
    return '$startMonth ${startOfWeek.day} - $endMonth ${endOfWeek.day}, ${endOfWeek.year}';
  }

  // If different months: "Sep 29 - Oct 5, 2025"
  return '$startMonth ${startOfWeek.day} - $endMonth ${endOfWeek.day}, ${endOfWeek.year}';
}

/// Gets the start of the week (Monday) for a given date
DateTime getStartOfWeek(DateTime date) {
  return _getStartOfWeek(date);
}

DateTime _getStartOfWeek(DateTime date) {
  final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
  return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
}

/// Gets the list of week start dates for the last N weeks (including current)
/// Returns list in chronological order (oldest first)
List<DateTime> getLastNWeeks(int n, {DateTime? referenceDate}) {
  final now = referenceDate ?? DateTime.now();
  final currentWeekStart = _getStartOfWeek(now);

  final weeks = <DateTime>[];
  for (int i = n - 1; i >= 0; i--) {
    final weekStart = currentWeekStart.subtract(Duration(days: i * 7));
    weeks.add(weekStart);
  }

  return weeks;
}

/// Determines which month label to show for a given week in a 12-week chart
/// Returns the month abbreviation if it's the first week of that month in the chart
/// Otherwise returns null
String? getMonthLabelForWeek(DateTime weekStart, List<DateTime> allWeeks) {
  final weekMonth = weekStart.month;
  final weekIndex = allWeeks.indexOf(weekStart);

  if (weekIndex == -1) return null;

  // First week always gets a label
  if (weekIndex == 0) {
    return monthAbbreviations[weekMonth - 1].toUpperCase();
  }

  // Check if previous week was in a different month
  final prevWeek = allWeeks[weekIndex - 1];
  if (prevWeek.month != weekMonth) {
    return monthAbbreviations[weekMonth - 1].toUpperCase();
  }

  return null;
}
