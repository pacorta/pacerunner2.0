import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/run_summary_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/distance_unit_provider.dart';
import '../../widgets/distance_unit_conversion.dart';

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
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade800,
          title: const Text(
            'Delete Run',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to delete this run? This action cannot be undone.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRun(docId);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
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
          title: const Text('Activities'),
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                Color.fromRGBO(140, 82, 255, 1.0),
                Color.fromRGBO(255, 87, 87, 1.0),
              ],
            ),
          ),
          child: Column(
            children: [
              //if (widget.newRunData != null)
              //  _displayCurrentRunStats(widget.newRunData!),
              Expanded(
                child: _buildRunList(),
              ),
            ],
          ),
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
                        // Return to root (RootShell) so bottom nav persists
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
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
        final runs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: runs.length,
          itemBuilder: (context, index) {
            final run = runs[index].data() as Map<String, dynamic>;
            final docId = runs[index].id;
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
                            IconButton(
                              icon: const Icon(Icons.info_outline,
                                  color: Colors.white, size: 16),
                              onPressed: () {},
                              padding: const EdgeInsets.all(2),
                              constraints: const BoxConstraints(
                                  minWidth: 24, minHeight: 24),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share,
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
          },
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
    try {
      _shareExportWithoutBackground.value = true;
      await Future.delayed(const Duration(milliseconds: 16));
      final boundary = _shareRepaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      // Copiar PNG real al portapapeles (no base64)
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        throw Exception('Clipboard not available on this platform');
      }
      final item = DataWriterItem();
      item.add(Formats.png(bytes));
      await clipboard.write([item]);
      if (mounted) {
        _shareExportWithoutBackground.value = false;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Image copied! Paste in Instagram Story.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        _shareExportWithoutBackground.value = false;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to copy image'),
          backgroundColor: Colors.red,
        ));
      }
    }
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
