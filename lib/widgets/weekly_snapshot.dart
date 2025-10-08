import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'distance_unit_provider.dart';
import 'distance_unit_conversion.dart';
import 'weekly_line_chart.dart';
import 'stats_view_mode_provider.dart';
import 'stats_segmented_control.dart';
import 'selected_week_provider.dart';
import 'selected_day_provider.dart';
import '../utils/date_utils.dart' as date_utils;

class WeeklySnapshot extends ConsumerWidget {
  final bool debugMode;

  const WeeklySnapshot({super.key, this.debugMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final unit = ref.watch(distanceUnitProvider);
    final viewMode = ref.watch(statsViewModeProvider);
    final selectedWeekIndex = ref.watch(selectedWeekProvider);
    final selectedDayIndex = ref.watch(selectedDayProvider);

    // Listen for view mode changes and reset selections appropriately
    ref.listen<StatsViewMode>(statsViewModeProvider, (previous, current) {
      if (previous != current) {
        if (current == StatsViewMode.last12Weeks) {
          // Entering 12-week mode: reset to most recent week
          ref.read(selectedWeekProvider.notifier).resetToMostRecent();
        } else if (current == StatsViewMode.currentWeek) {
          // Entering week mode: clear day selection (show week totals)
          ref.read(selectedDayProvider.notifier).clearSelection();
        }
      }
    });

    if (userId == null && !debugMode) {
      return const SizedBox.shrink();
    }

    // Calculate date references
    final now = DateTime.now();

    // Debug mode: return fake data
    if (debugMode) {
      return _buildDebugSnapshot(
          unit, viewMode, selectedWeekIndex, selectedDayIndex, ref);
    }

    // Get all 12 weeks to map selected index to actual dates
    final weeks = date_utils.getLastNWeeks(12, referenceDate: now);

    // Determine which week to display in Week mode
    // Use selected week from 12-week mode, or current week if index is 11
    final selectedWeekStart = weeks[selectedWeekIndex];

    // Calculate date range based on view mode
    DateTime queryStartDate;
    if (viewMode == StatsViewMode.currentWeek) {
      // Week mode: query only the selected week
      queryStartDate = selectedWeekStart;
    } else {
      // Last 12 weeks: query all 12 weeks
      queryStartDate = weeks[0]; // Start from oldest week
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('runs')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(queryStartDate))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final runs = snapshot.data!.docs;

        // Calculate stats based on view mode
        Map<String, dynamic> stats;
        if (viewMode == StatsViewMode.currentWeek) {
          // Show daily breakdown for selected week (or individual day if selected)
          stats = _calculateWeeklyStats(
              runs, unit, selectedWeekStart, now, selectedDayIndex);
        } else {
          stats = _calculate12WeekStats(runs, unit, now, selectedWeekIndex);
        }

        // Always show the snapshot, even with 0 data
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color.fromRGBO(255, 87, 87, 1.0),
                Color.fromRGBO(140, 82, 255, 1.0),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            margin: const EdgeInsets.all(2), // gradient border thickness
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color.fromARGB(205, 255, 255, 255),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Segmented Control
                const StatsSegmentedControl(),
                const SizedBox(height: 16),

                // Title with optional clear button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stats['title'],
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Show clear button only when a day is selected in week mode
                    if (viewMode == StatsViewMode.currentWeek &&
                        selectedDayIndex != null)
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(selectedDayProvider.notifier)
                              .clearSelection();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.black.withOpacity(0.4),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Distance and Time stats in a row
                    Row(
                      children: [
                        // Distance
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'distance',
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                stats['totalDistance'] == 0.0
                                    ? '0.0 ${stats['unit']}'
                                    : '${stats['totalDistance'].toStringAsFixed(1)} ${stats['unit']}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'time',
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                stats['totalDistance'] == 0.0
                                    ? '0 minutes'
                                    : stats['totalTime'],
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Bottom: Line chart with transparent background
                    Container(
                      height: 180,
                      width: double.infinity,
                      child: WeeklyLineChart(
                        data: stats['chartData'],
                        unitLabel: stats['unit'] == 'miles' ? 'mi' : 'km',
                        showAvgToggle: false,
                        mode: stats['chartMode'],
                        xAxisLabels: stats['xAxisLabels'],
                        // Week selection (12-week mode)
                        selectedWeekIndex: viewMode == StatsViewMode.last12Weeks
                            ? selectedWeekIndex
                            : null,
                        onWeekTap: viewMode == StatsViewMode.last12Weeks
                            ? (index) {
                                ref
                                    .read(selectedWeekProvider.notifier)
                                    .selectWeek(index);
                              }
                            : null,
                        // Day selection (week mode)
                        selectedDayIndex: viewMode == StatsViewMode.currentWeek
                            ? selectedDayIndex
                            : null,
                        onDayTap: viewMode == StatsViewMode.currentWeek
                            ? (index) {
                                ref
                                    .read(selectedDayProvider.notifier)
                                    .selectDay(index);
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _calculateWeeklyStats(
      List<QueryDocumentSnapshot> runs,
      DistanceUnit unit,
      DateTime startOfWeek,
      DateTime now,
      int? selectedDayIndex) {
    double totalDistanceKm = 0.0;
    int totalTimeInSeconds = 0;

    // Calculate end of week (Sunday at end of day)
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    // Initialize daily data array [Monday=0, Tuesday=1, ..., Sunday=6]
    List<double> dailyDistanceKm = List.filled(7, 0.0);
    List<int> dailyTimeSeconds = List.filled(7, 0);

    if (runs.isNotEmpty) {
      for (var doc in runs) {
        final run = doc.data() as Map<String, dynamic>;

        // Get timestamp and filter to only include runs from this specific week
        final timestamp = (run['timestamp'] as Timestamp?)?.toDate();
        if (timestamp == null) continue;

        // Skip runs outside this week's range
        if (timestamp.isBefore(startOfWeek) || timestamp.isAfter(endOfWeek)) {
          continue;
        }

        // Get distance and convert to km for internal calculation
        final distance = (run['distance'] as num?)?.toDouble() ?? 0.0;
        final storedUnit = run['distanceUnitString']?.toString() ?? 'km';

        double distanceInKm = distance;
        if (storedUnit == 'mi') {
          distanceInKm = milesToKilometers(distance);
        }
        totalDistanceKm += distanceInKm;

        // Parse time (format: "HH:MM:SS")
        final timeString = run['time']?.toString() ?? '00:00:00';
        final timeSeconds = _parseTimeStringToSeconds(timeString);
        totalTimeInSeconds += timeSeconds;

        // Add to daily data
        final dayOfWeek =
            timestamp.weekday - 1; // Convert to 0-indexed (Monday=0)
        if (dayOfWeek >= 0 && dayOfWeek < 7) {
          dailyDistanceKm[dayOfWeek] += distanceInKm;
          dailyTimeSeconds[dayOfWeek] += timeSeconds;
        }
      }
    }

    // Convert daily distances to user's preferred unit
    List<double> dailyDisplayDistance = dailyDistanceKm;
    if (unit == DistanceUnit.miles) {
      dailyDisplayDistance =
          dailyDistanceKm.map((d) => kilometersToMiles(d)).toList();
    }

    // Determine what stats to show based on selection
    double displayDistance;
    int displayTimeSeconds;
    String title;

    if (selectedDayIndex != null) {
      // Show individual day stats
      displayDistance = dailyDistanceKm[selectedDayIndex];
      displayTimeSeconds = dailyTimeSeconds[selectedDayIndex];

      // Format day title (e.g., "Monday, Oct 6" or "Today")
      final selectedDate = startOfWeek.add(Duration(days: selectedDayIndex));
      title = _formatDayTitle(selectedDate, now);
    } else {
      // Show week totals
      displayDistance = totalDistanceKm;
      displayTimeSeconds = totalTimeInSeconds;
      title = date_utils.formatWeekRange(startOfWeek, referenceDate: now);
    }

    // Convert distance to user's preferred unit
    String unitLabel = 'km';
    if (unit == DistanceUnit.miles) {
      displayDistance = kilometersToMiles(displayDistance);
      unitLabel = 'miles';
    }

    // Format time
    String formattedTime = _formatTotalTime(displayTimeSeconds);

    return {
      'title': title,
      'totalDistance': displayDistance,
      'totalTime': formattedTime,
      'unit': unitLabel,
      'chartData': dailyDisplayDistance,
      'chartMode': ChartMode.week,
      'xAxisLabels': null,
    };
  }

  /// Format day title for individual day view
  String _formatDayTitle(DateTime date, DateTime now) {
    final dayName = date_utils.dayNamesFull[date.weekday - 1];

    // Check if it's today
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }

    // Check if it's yesterday
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }

    // Format as "Monday, Oct 6"
    final monthAbbr = date_utils.monthAbbreviations[date.month - 1];
    return '$dayName, $monthAbbr ${date.day}';
  }

  /// Calculate stats for the last 12 weeks
  /// Returns data for the SELECTED week (not totals of all 12 weeks)
  Map<String, dynamic> _calculate12WeekStats(List<QueryDocumentSnapshot> runs,
      DistanceUnit unit, DateTime now, int selectedWeekIndex) {
    // Get the 12 week boundaries
    final weeks = date_utils.getLastNWeeks(12, referenceDate: now);

    // Initialize weekly data array [Week 0...Week 11]
    List<double> weeklyDistanceKm = List.filled(12, 0.0);
    List<int> weeklyTimeSeconds = List.filled(12, 0);

    if (runs.isNotEmpty) {
      for (var doc in runs) {
        final run = doc.data() as Map<String, dynamic>;

        // Get timestamp
        final timestamp = (run['timestamp'] as Timestamp?)?.toDate();
        if (timestamp == null) continue;

        // Find which week this run belongs to
        int weekIndex = -1;
        for (int i = 0; i < weeks.length; i++) {
          final weekStart = weeks[i];
          final weekEnd = weekStart.add(const Duration(days: 7));
          if (timestamp
                  .isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
              timestamp.isBefore(weekEnd)) {
            weekIndex = i;
            break;
          }
        }

        if (weekIndex == -1) continue; // Run doesn't fall in any of our weeks

        // Get distance and convert to km
        final distance = (run['distance'] as num?)?.toDouble() ?? 0.0;
        final storedUnit = run['distanceUnitString']?.toString() ?? 'km';

        double distanceInKm = distance;
        if (storedUnit == 'mi') {
          distanceInKm = milesToKilometers(distance);
        }
        weeklyDistanceKm[weekIndex] += distanceInKm;

        // Parse time
        final timeString = run['time']?.toString() ?? '00:00:00';
        weeklyTimeSeconds[weekIndex] += _parseTimeStringToSeconds(timeString);
      }
    }

    // Convert weekly distances to user's preferred unit for chart display
    List<double> weeklyDisplayDistance = weeklyDistanceKm;
    if (unit == DistanceUnit.miles) {
      weeklyDisplayDistance =
          weeklyDistanceKm.map((d) => kilometersToMiles(d)).toList();
    }

    // Get the SELECTED week's data (not totals of all 12 weeks)
    final selectedWeekDistanceKm = weeklyDistanceKm[selectedWeekIndex];
    final selectedWeekTimeSeconds = weeklyTimeSeconds[selectedWeekIndex];

    double displayDistance = selectedWeekDistanceKm;
    String unitLabel = 'km';
    if (unit == DistanceUnit.miles) {
      displayDistance = kilometersToMiles(selectedWeekDistanceKm);
      unitLabel = 'miles';
    }

    // Format selected week's time
    String formattedTime = _formatTotalTime(selectedWeekTimeSeconds);

    // Generate x-axis labels (month abbreviations)
    List<String> xAxisLabels = List.generate(
        12, (i) => date_utils.getMonthLabelForWeek(weeks[i], weeks) ?? '');

    // Get title for the selected week
    final selectedWeek = weeks[selectedWeekIndex];
    final title = date_utils.formatWeekRange(selectedWeek, referenceDate: now);

    return {
      'title': title,
      'totalDistance': displayDistance,
      'totalTime': formattedTime,
      'unit': unitLabel,
      'chartData': weeklyDisplayDistance,
      'chartMode': ChartMode.twelveWeeks,
      'xAxisLabels': xAxisLabels,
    };
  }

  int _parseTimeStringToSeconds(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 3) return 0;

      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = int.tryParse(parts[2]) ?? 0;

      return hours * 3600 + minutes * 60 + seconds;
    } catch (e) {
      return 0;
    }
  }

  String _formatTotalTime(int totalSeconds) {
    if (totalSeconds == 0) return '0 hours';

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}:${minutes.toString().padLeft(2, '0')} hours';
      } else {
        return '$hours hours';
      }
    } else {
      return '$minutes minutes';
    }
  }

  // Debug mode: build snapshot with fake data
  Widget _buildDebugSnapshot(DistanceUnit unit, StatsViewMode viewMode,
      int selectedWeekIndex, int? selectedDayIndex, WidgetRef ref) {
    // Generate fake data based on mode
    List<double> fakeDataKm;
    ChartMode chartMode;
    List<String>? xAxisLabels;
    String title;

    final now = DateTime.now();
    final weeks = date_utils.getLastNWeeks(12, referenceDate: now);

    if (viewMode == StatsViewMode.currentWeek) {
      // Fake daily data - represents a realistic week
      // Monday=0, Tuesday=1, ..., Sunday=6
      fakeDataKm = [
        5.2,
        0.0,
        8.3,
        3.1,
        10.5,
        0.0,
        15.8
      ]; // Rest days on Tue & Sat
      chartMode = ChartMode.week;
      xAxisLabels = null;
      // Show selected week's title
      title = date_utils.formatWeekRange(weeks[selectedWeekIndex],
          referenceDate: now);
    } else {
      // Fake 12-week data
      fakeDataKm = [
        12.5, 15.3, 8.7, 22.1, 18.4, 11.2, // Weeks 1-6
        25.8, 19.6, 14.3, 28.2, 21.7, 16.9, // Weeks 7-12
      ];
      chartMode = ChartMode.twelveWeeks;
      // Generate fake month labels
      xAxisLabels = List.generate(
          12, (i) => date_utils.getMonthLabelForWeek(weeks[i], weeks) ?? '');
      title = date_utils.formatWeekRange(weeks[selectedWeekIndex],
          referenceDate: now);
    }

    // Convert to user's preferred unit
    List<double> chartData = fakeDataKm;
    String unitLabel = 'km';
    // For 12-week mode: show selected week's data, not total
    double totalDistance = viewMode == StatsViewMode.currentWeek
        ? fakeDataKm.fold(0.0, (a, b) => a + b)
        : fakeDataKm[selectedWeekIndex];

    if (unit == DistanceUnit.miles) {
      chartData = fakeDataKm.map((d) => kilometersToMiles(d)).toList();
      totalDistance = kilometersToMiles(totalDistance);
      unitLabel = 'miles';
    }

    // Fake total time (about 5:30 min/km average pace)
    final int totalTimeInSeconds = (totalDistance * 330).round(); // ~5:30 pace
    final String formattedTime = _formatTotalTime(totalTimeInSeconds);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.fromRGBO(255, 87, 87, 1.0),
            Color.fromRGBO(140, 82, 255, 1.0),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        margin: const EdgeInsets.all(2), // gradient border thickness
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(219, 255, 255, 255),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Control
            const StatsSegmentedControl(),
            const SizedBox(height: 16),

            // Title with debug indicator and optional clear button
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Show clear button only when a day is selected in week mode
                if (viewMode == StatsViewMode.currentWeek &&
                    selectedDayIndex != null)
                  GestureDetector(
                    onTap: () {
                      ref.read(selectedDayProvider.notifier).clearSelection();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'DEBUG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: Distance and Time stats in a row
                Row(
                  children: [
                    // Distance
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'distance',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            '${totalDistance.toStringAsFixed(1)} $unitLabel',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'time',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                // Bottom: Line chart with transparent background
                Container(
                  height: 180,
                  width: double.infinity,
                  child: WeeklyLineChart(
                    data: chartData,
                    unitLabel: unitLabel == 'miles' ? 'mi' : 'km',
                    showAvgToggle: false,
                    mode: chartMode,
                    xAxisLabels: xAxisLabels,
                    // Week selection (12-week mode)
                    selectedWeekIndex: viewMode == StatsViewMode.last12Weeks
                        ? selectedWeekIndex
                        : null,
                    onWeekTap: viewMode == StatsViewMode.last12Weeks
                        ? (index) {
                            ref
                                .read(selectedWeekProvider.notifier)
                                .selectWeek(index);
                          }
                        : null,
                    // Day selection (week mode)
                    selectedDayIndex: viewMode == StatsViewMode.currentWeek
                        ? selectedDayIndex
                        : null,
                    onDayTap: viewMode == StatsViewMode.currentWeek
                        ? (index) {
                            ref
                                .read(selectedDayProvider.notifier)
                                .selectDay(index);
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
