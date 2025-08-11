import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import '../../home_screen.dart';
//import '../../widgets/distance_unit_as_string_provider.dart';

class RunningStatsPage extends StatefulWidget {
  final Map<String, dynamic>? newRunData;

  const RunningStatsPage({super.key, this.newRunData});

  @override
  _RunningStatsPageState createState() => _RunningStatsPageState();
}

class _RunningStatsPageState extends State<RunningStatsPage> {
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
              if (widget.newRunData != null)
                _displayCurrentRunStats(widget.newRunData!),
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
                        Navigator.of(context).pop();
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
          Text(
              'Distance: ${runData['distance'].toStringAsFixed(2)} ${runData['distanceUnitString']}'), //tested and works [nov 20, 2024]
          Text('Time: ${runData['time']}'),
          Text('Average Pace: ${runData['averagePace']}'),
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
                              onPressed: () {},
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
                            '${run['distance'].toStringAsFixed(2)} ${run['distanceUnitString']}',
                          ),
                        ),
                        Expanded(
                          child: _buildMetricWithIcon(
                            Icons.speed,
                            'Pace',
                            run['averagePace'],
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
