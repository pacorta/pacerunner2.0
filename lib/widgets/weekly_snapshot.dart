import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'distance_unit_provider.dart';
import 'distance_unit_conversion.dart';
import 'weekly_line_chart.dart';

class WeeklySnapshot extends ConsumerWidget {
  final bool debugMode;

  const WeeklySnapshot({super.key, this.debugMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final unit = ref.watch(distanceUnitProvider);

    if (userId == null && !debugMode) {
      return const SizedBox.shrink();
    }

    // Calculate the start of current week (Monday)
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekMidnight =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    // Debug mode: return fake data
    if (debugMode) {
      return _buildDebugSnapshot(unit);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('runs')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeekMidnight))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final runs = snapshot.data!.docs;
        final weeklyStats = _calculateWeeklyStats(runs, unit, startOfWeek);

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
                // Title
                Text(
                  'Weekly snapshot',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (weeklyStats['totalDistance'] == 0.0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'No activities this week yet',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
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
                                weeklyStats['totalDistance'] == 0.0
                                    ? '0.0 ${weeklyStats['unit']}'
                                    : '${weeklyStats['totalDistance'].toStringAsFixed(1)} ${weeklyStats['unit']}',
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
                                weeklyStats['totalDistance'] == 0.0
                                    ? '0 minutes'
                                    : weeklyStats['totalTime'],
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
                        data: weeklyStats['dailyData'],
                        unitLabel: weeklyStats['unit'] == 'miles' ? 'mi' : 'km',
                        showAvgToggle: false,
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

  Map<String, dynamic> _calculateWeeklyStats(List<QueryDocumentSnapshot> runs,
      DistanceUnit unit, DateTime startOfWeek) {
    double totalDistanceKm = 0.0;
    int totalTimeInSeconds = 0;

    // Initialize daily data array [Monday=0, Tuesday=1, ..., Sunday=6]
    List<double> dailyDistanceKm = List.filled(7, 0.0);

    if (runs.isNotEmpty) {
      for (var doc in runs) {
        final run = doc.data() as Map<String, dynamic>;

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
        totalTimeInSeconds += _parseTimeStringToSeconds(timeString);

        // Add to daily data
        final timestamp = (run['timestamp'] as Timestamp?)?.toDate();
        if (timestamp != null) {
          final dayOfWeek =
              timestamp.weekday - 1; // Convert to 0-indexed (Monday=0)
          if (dayOfWeek >= 0 && dayOfWeek < 7) {
            dailyDistanceKm[dayOfWeek] += distanceInKm;
          }
        }
      }
    }

    // Convert daily distances to user's preferred unit
    List<double> dailyDisplayDistance = dailyDistanceKm;
    if (unit == DistanceUnit.miles) {
      dailyDisplayDistance =
          dailyDistanceKm.map((d) => kilometersToMiles(d)).toList();
    }

    // Convert total distance to user's preferred unit for display
    double displayDistance = totalDistanceKm;
    String unitLabel = 'km';
    if (unit == DistanceUnit.miles) {
      displayDistance = kilometersToMiles(totalDistanceKm);
      unitLabel = 'miles';
    }

    // Format total time
    String formattedTime = _formatTotalTime(totalTimeInSeconds);

    return {
      'totalDistance': displayDistance,
      'totalTime': formattedTime,
      'unit': unitLabel,
      'dailyData': dailyDisplayDistance,
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
  Widget _buildDebugSnapshot(DistanceUnit unit) {
    // Fake daily data - represents a realistic week
    // Monday=0, Tuesday=1, ..., Sunday=6
    final List<double> fakeDataKm = [
      5.2,
      0.0,
      8.3,
      3.1,
      10.5,
      0.0,
      15.8
    ]; // Rest days on Tue & Sat

    // Convert to user's preferred unit
    List<double> dailyData = fakeDataKm;
    String unitLabel = 'km';
    double totalDistance = fakeDataKm.fold(0.0, (a, b) => a + b);

    if (unit == DistanceUnit.miles) {
      dailyData = fakeDataKm.map((d) => kilometersToMiles(d)).toList();
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
            // Title with debug indicator
            Row(
              children: [
                Text(
                  'Weekly snapshot',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
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
                    data: dailyData,
                    unitLabel: unitLabel == 'miles' ? 'mi' : 'km',
                    showAvgToggle: false,
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
