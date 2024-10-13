import 'package:flutter/material.dart';
import 'package:untitled/widgets/elapsed_time_provider.dart';
import 'dart:async';
import 'map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'speed_provider.dart';
import 'distance_provider.dart';
import 'average_pace_provider.dart';
//import 'current_pace_in_seconds_provider.dart';
import 'current_pace_provider.dart';
import 'pace_bar.dart';

class CurrentRun extends ConsumerStatefulWidget {
  const CurrentRun({super.key});

  @override
  ConsumerState<CurrentRun> createState() => _CurrentRunState();
}

class _CurrentRunState extends ConsumerState<CurrentRun> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  //String _elapsedTime = '00:00:00';

/*
  double avgPace(){
    return _elapsedTime/ref.read(distanceProvider).toStringAsFixed(2);
  }
*/

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        final newTime = _formatDuration(_stopwatch.elapsed);
        ref.read(elapsedTimeProvider.notifier).state = newTime;
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _endRun() {
    //_distanceCalculator.stop();
    _stopwatch.stop();
    _timer?.cancel();
    // Add code to save the run data, show a summary, etc.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run Completed'),
        content: Text(
            'Run Time: ${ref.read(elapsedTimeProvider)} \nTraveled distance: ${ref.read(formattedDistanceProvider)}\nAverage Pace: ${ref.read(averagePaceProvider)} '),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              //reset time and distance to 0.

              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to home screen
              /*
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const Results()), //Results is not accessible yet :(
              );
              */
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final speed = ref.watch(formattedSpeedProvider);
    final formattedDistance = ref.watch(formattedDistanceProvider); //#km2miles
    final elapsedTime = ref.watch(elapsedTimeProvider);
    final avgPace = ref.watch(averagePaceProvider);
    final currentPace = ref.watch(currentPaceProvider);

    return Scaffold(
      backgroundColor: Colors.teal,
      appBar: AppBar(
        title: const Text('Current Run'),
        backgroundColor: const Color.fromARGB(255, 157, 210, 223),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                const SizedBox(
                  height: 500,
                  child: Map(),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      elapsedTime,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                /*
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'SPEED: $speed',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                */
                const PaceBar(),
                /*
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'AVERAGE PACE: $avgPace',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                */
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'CURRENT PACE: $currentPace',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'DISTANCE: $formattedDistance',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _endRun,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('STOP', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
