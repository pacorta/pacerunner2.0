import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/run_summary_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/distance_unit_provider.dart';
import '../../widgets/distance_unit_conversion.dart';
import '../../widgets/weekly_snapshot.dart';
import '../../widgets/settings_sheet.dart';
import '../../root_shell.dart';
import '../../widgets/inline_goal_input.dart';
import '../../widgets/add_manual_activity_modal.dart';
import '../../widgets/stats_view_mode_provider.dart';
import '../../widgets/selected_week_provider.dart';
import '../../widgets/selected_day_provider.dart';
import '../../utils/date_utils.dart' as date_utils;
import '../../services/clipboard_service.dart';

// import '../../home_screen.dart';
//import '../../widgets/distance_unit_as_string_provider.dart';

class RunningStatsPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? newRunData;

  const RunningStatsPage({super.key, this.newRunData});

  @override
  _RunningStatsPageState createState() => _RunningStatsPageState();
}

class _RunningStatsPageState extends ConsumerState<RunningStatsPage> {
  // Share dialog render/export helpers
  final GlobalKey _shareRepaintKey = GlobalKey();
  final ValueNotifier<bool> _shareExportWithoutBackground =
      ValueNotifier(false);

  void _deleteRun(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('runs')
          .doc(docId)
          .delete();
      print('Run deleted successfully');
    } catch (e) {
      print('Error deleting run: $e');
    }
  }

  void _confirmDeleteRun(String docId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red.shade600, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Run',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this run?',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF34495E),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone. Your run data will be permanently deleted.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteRun(docId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete Run',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _openSettingsSheet() {
    SettingsSheet.show(context);
  }

  void _openAddManualActivityModal() async {
    final result = await showAddManualActivityModal(context);
    // Modal returns true if activity was saved successfully
    // The StreamBuilder will automatically refresh the list
    if (result == true && mounted) {
      // Optional: Could add additional feedback here if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color.fromRGBO(255, 87, 87, 1.0),
                Color.fromRGBO(140, 82, 255, 1.0),
              ],
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: _openSettingsSheet,
          tooltip: 'Settings',
        ),
        title: const Text('Activities'),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _openAddManualActivityModal,
            tooltip: 'Add Manual Activity',
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Color.fromRGBO(140, 82, 255, 1.0),
                  Color.fromRGBO(255, 87, 87, 1.0),
                ],
              ),
            ),
          ),
          // Scrollable content
          SingleChildScrollView(
            child: Column(
              children: [
                //if (widget.newRunData != null)
                //  _displayCurrentRunStats(widget.newRunData!),
                const WeeklySnapshot(debugMode: false),
                _buildRunList(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              Color.fromRGBO(140, 82, 255, 1.0),
              Color.fromRGBO(255, 87, 87, 1.0),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // Clear any active goal so Home is blank when returning
                      clearGoalProviders(ref);
                      // Navigate back to home and clear the navigation stack
                      Navigator.pushAndRemoveUntil(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const RootShell(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return child; // No transition
                          },
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                        (route) => false, // Remove all routes from the stack
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home,
                            color: Colors.white.withOpacity(0.5), size: 26),
                        const SizedBox(height: 2),
                        Text('Home',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.bar_chart, color: Colors.white, size: 26),
                      SizedBox(height: 2),
                      Text('Stats',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _displayCurrentRunStats(Map<String, dynamic> runData) {
    final unit = ref.watch(distanceUnitProvider);
    final String unitLabel = unit == DistanceUnit.kilometers ? 'km' : 'mi';

    final num stored = (runData['distance'] as num? ?? 0);
    final String storedUnit =
        (runData['distanceUnitString']?.toString() ?? 'mi');
    final String timeString = runData['time']?.toString() ?? '00:00:00';

    double display = stored.toDouble();
    if (storedUnit == 'mi' && unit == DistanceUnit.kilometers) {
      display = milesToKilometers(display);
    } else if (storedUnit == 'km' && unit == DistanceUnit.miles) {
      display = kilometersToMiles(display);
    }

    final String paceString = _computePaceString(
      timeString: timeString,
      distanceValue: stored.toDouble(),
      storedDistanceUnit: storedUnit,
      currentUnit: unit,
    );

    return Container(
      margin: const EdgeInsets.all(16), //spacing around container
      padding: const EdgeInsets.all(16), //padding inside container
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8), //semi-transparent bg
        borderRadius: BorderRadius.circular(15), //rounder corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), //subtle shadow
            blurRadius: 10, //blur effect for the shadow
            offset: const Offset(0, 5), //shadow offset
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Run Summary:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Distance: ${display.toStringAsFixed(2)} $unitLabel'),
          Text('Time: ${runData['time']}'),
          Text('Average Pace: $paceString'),
        ],
      ),
    );
  }

  Widget _buildRunList() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final viewMode = ref.watch(statsViewModeProvider);
    final selectedWeekIndex = ref.watch(selectedWeekProvider);
    final selectedDayIndex = ref.watch(selectedDayProvider);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('runs')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allRuns = snapshot.data!.docs;

        // Calculate date range for filtering
        DateTime? filterStartDate;
        DateTime? filterEndDate;

        if (viewMode == StatsViewMode.currentWeek) {
          // Get the selected week's start date
          final now = DateTime.now();
          final weeks = date_utils.getLastNWeeks(12, referenceDate: now);
          final selectedWeekStart = weeks[selectedWeekIndex];

          if (selectedDayIndex != null) {
            // Filter to specific day
            final selectedDate =
                selectedWeekStart.add(Duration(days: selectedDayIndex));
            filterStartDate = DateTime(
                selectedDate.year, selectedDate.month, selectedDate.day);
            filterEndDate = DateTime(selectedDate.year, selectedDate.month,
                selectedDate.day, 23, 59, 59);
          } else {
            // Filter to entire week
            filterStartDate = selectedWeekStart;
            filterEndDate = selectedWeekStart.add(const Duration(days: 7));
          }
        }

        // Filter runs based on date range
        final runs = (filterStartDate != null && filterEndDate != null)
            ? allRuns.where((doc) {
                final run = doc.data() as Map<String, dynamic>;
                final timestamp = (run['timestamp'] as Timestamp?)?.toDate();
                if (timestamp == null) return false;
                return timestamp.isAfter(filterStartDate!
                        .subtract(const Duration(seconds: 1))) &&
                    timestamp.isBefore(filterEndDate!);
              }).toList()
            : allRuns;

        if (runs.isEmpty) {
          // Show a message when there are no runs
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color.fromRGBO(255, 87, 87, 1.0),
                  Color.fromRGBO(140, 82, 255, 1.0),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 18, 36, 83),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.directions_run,
                    size: 48,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activities yet',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Go for a run to see your stats here!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: runs.map((doc) {
            final run = doc.data() as Map<String, dynamic>;
            final docId = doc.id;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color.fromRGBO(255, 87, 87, 1.0),
                    Color.fromRGBO(140, 82, 255, 1.0),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Container(
                margin: const EdgeInsets.all(2), // gradient border thickness
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 18, 36, 83),
                  borderRadius: BorderRadius.circular(16),
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
                    // Header: Date + Actions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _formatDateHeader(run['date'], run['startTime']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /*IconButton(
                              icon: const Icon(Icons.info_outline,
                                  color: Colors.white, size: 16),
                              onPressed: () {},
                              padding: const EdgeInsets.all(2),
                              constraints: const BoxConstraints(
                                  minWidth: 24, minHeight: 24),
                            ), */
                            IconButton(
                              icon: const Icon(Icons.ios_share,
                                  color: Colors.white, size: 16),
                              onPressed: () => _showShareDialog(run),
                              padding: const EdgeInsets.all(2),
                              constraints: const BoxConstraints(
                                  minWidth: 24, minHeight: 24),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.white, size: 16),
                              onPressed: () => _confirmDeleteRun(docId),
                              padding: const EdgeInsets.all(2),
                              constraints: const BoxConstraints(
                                  minWidth: 24, minHeight: 24),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Divider(
                      color: Colors.white.withOpacity(0.12),
                      height: 1,
                      thickness: 0.8,
                    ),
                    const SizedBox(height: 6),
                    // Metrics Grid: Distance | Pace | Time with icons
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricWithIcon(
                            Icons.route,
                            'Distance',
                            (() {
                              final unit = ref.watch(distanceUnitProvider);
                              final String unitLabel =
                                  unit == DistanceUnit.kilometers ? 'km' : 'mi';

                              final num stored = (run['distance'] as num? ?? 0);
                              final String storedUnit =
                                  (run['distanceUnitString']?.toString() ??
                                      'mi');

                              double display = stored.toDouble();
                              if (storedUnit == 'mi' &&
                                  unit == DistanceUnit.kilometers) {
                                display = milesToKilometers(display);
                              } else if (storedUnit == 'km' &&
                                  unit == DistanceUnit.miles) {
                                display = kilometersToMiles(display);
                              }
                              return '${display.toStringAsFixed(2)} $unitLabel';
                            })(),
                          ),
                        ),
                        Expanded(
                          child: _buildMetricWithIcon(
                            Icons.speed,
                            'Pace',
                            (() {
                              final unit = ref.watch(distanceUnitProvider);
                              final String storedUnit =
                                  (run['distanceUnitString']?.toString() ??
                                      'mi');
                              final num storedDistance =
                                  (run['distance'] as num? ?? 0);
                              final String timeString =
                                  run['time']?.toString() ?? '00:00:00';
                              return _computePaceString(
                                timeString: timeString,
                                distanceValue: storedDistance.toDouble(),
                                storedDistanceUnit: storedUnit,
                                currentUnit: unit,
                              );
                            })(),
                          ),
                        ),
                        Expanded(
                          child: _buildMetricWithIcon(
                            Icons.timer,
                            'Time',
                            run['time'],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Opens a modal with a RunSummaryCard for the selected activity.
  void _showShareDialog(Map<String, dynamic> run) {
    // Attempt to decode a future map snapshot if present. For MVP this will be null.
    Uint8List? mapSnapshot;
    final dynamic snapshotBase64 = run['mapSnapshotBase64'];
    if (snapshotBase64 is String && snapshotBase64.isNotEmpty) {
      try {
        final String cleaned = snapshotBase64.contains(',')
            ? snapshotBase64.split(',').last
            : snapshotBase64;
        mapSnapshot = base64Decode(cleaned);
      } catch (_) {}
    }

    final num storedDistance = (run['distance'] as num? ?? 0);
    final String storedUnitStr = run['distanceUnitString']?.toString() ?? 'mi';

    final unit = ref.watch(distanceUnitProvider);
    final String unitLabel = unit == DistanceUnit.kilometers ? 'km' : 'mi';

    double displayDistance = storedDistance.toDouble();
    if (storedUnitStr == 'mi' && unit == DistanceUnit.kilometers) {
      displayDistance = milesToKilometers(displayDistance);
    } else if (storedUnitStr == 'km' && unit == DistanceUnit.miles) {
      displayDistance = kilometersToMiles(displayDistance);
    }

    final String distance = displayDistance.toStringAsFixed(2);
    final String pace = _computePaceString(
      timeString: run['time']?.toString() ?? '00:00:00',
      distanceValue: storedDistance.toDouble(),
      storedDistanceUnit: storedUnitStr,
      currentUnit: unit,
    );
    final String time = run['time']?.toString() ?? '';

    // Goal achievement data (available for future features)
    final bool goalAchieved = run['goalAchieved'] ?? false;
    final int? goalCompletionTimeSeconds = run['goalCompletionTimeSeconds'];
    // Example usage:
    // if (goalAchieved) {
    //   // Show goal achievement badge 🎯
    //   // Show completion time if available
    // }

    showDialog(
      context: context,
      barrierDismissible: true, // tap outside closes
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _shareExportWithoutBackground,
                builder: (context, hideBackground, _) {
                  return RepaintBoundary(
                    key: _shareRepaintKey,
                    child: RunSummaryCard(
                      mapSnapshot: mapSnapshot, // null for now
                      distance: distance,
                      pace: pace,
                      time: time,
                      distanceUnit: unitLabel,
                      showCardBackground: !hideBackground,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _shareDialogCopyToClipboard,
                  child: Column(
                    children: const [
                      Text('Copy to clipboard',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareDialogCopyToClipboard() async {
    await ClipboardService.copyWidgetToClipboard(
      repaintKey: _shareRepaintKey,
      context: context,
      backgroundToggle: _shareExportWithoutBackground,
    );
  }

  Widget _buildMetricWithIcon(IconData icon, String label, String value) {
    // Format time if needed using existing logic
    String displayValue = value;
    if (label == 'Time' && value.contains(':')) {
      displayValue = _formatRunTime(value);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white.withOpacity(0.8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 9,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          displayValue,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// Pace helpers
int _parseHhMmSsToSeconds(String timeString) {
  // Expected "hh:mm:ss"
  final parts = timeString.split(':');
  if (parts.length != 3) {
    return 0;
  }
  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;
  final seconds = int.tryParse(parts[2]) ?? 0;
  return hours * 3600 + minutes * 60 + seconds;
}

String _computePaceString({
  required String timeString,
  required double distanceValue,
  required String storedDistanceUnit, // 'km' or 'mi'
  required DistanceUnit currentUnit,
}) {
  final elapsedSeconds = _parseHhMmSsToSeconds(timeString);
  if (elapsedSeconds <= 0 || distanceValue <= 0) {
    return '---';
  }

  // Convert distance into the unit we want to display pace
  double distanceInCurrentUnit = distanceValue;
  if (storedDistanceUnit == 'mi' && currentUnit == DistanceUnit.kilometers) {
    distanceInCurrentUnit = milesToKilometers(distanceInCurrentUnit);
  } else if (storedDistanceUnit == 'km' && currentUnit == DistanceUnit.miles) {
    distanceInCurrentUnit = kilometersToMiles(distanceInCurrentUnit);
  }

  final paceSecondsPerUnit = elapsedSeconds / distanceInCurrentUnit;
  final minutes = (paceSecondsPerUnit / 60).floor();
  final seconds = (paceSecondsPerUnit % 60).round();
  final unitLabel = currentUnit == DistanceUnit.kilometers ? 'km' : 'mi';
  return '$minutes:${seconds.toString().padLeft(2, '0')}/$unitLabel';
}

String _formatTime(String? isoString) {
  if (isoString == null) return 'Unknown';
  DateTime dateTime = DateTime.parse(isoString);
  int hour = dateTime.hour;
  int minute = dateTime.minute;
  String period = hour >= 12 ? 'PM' : 'AM';
  hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  return '$hour:${minute.toString().padLeft(2, '0')} $period';
}

String _formatDateHeader(String? date, String? startTime) {
  if (date == null || startTime == null) return 'Unknown';
  DateTime dateTime = DateTime.parse(date);
  List<String> months = [
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
  String formattedDate =
      '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  String formattedTime = _formatTime(startTime);
  return '$formattedDate at $formattedTime';
}

String _formatRunTime(String timeString) {
  // Convert "00:00:43" to "43s" or "00:28:34" to "28m 34s"
  List<String> parts = timeString.split(':');
  if (parts.length != 3) return timeString;

  int hours = int.tryParse(parts[0]) ?? 0;
  int minutes = int.tryParse(parts[1]) ?? 0;
  int seconds = int.tryParse(parts[2]) ?? 0;

  if (hours > 0) {
    return '${hours}h ${minutes}m ${seconds}s';
  } else if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  } else {
    return '${seconds}s';
  }
}

// Old _buildMetric removed in favor of _buildMetricWithIcon for improved UI
