import 'package:flutter/material.dart';
import 'dart:async';
import 'map.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'speed_provider.dart';

/*
class CurrentRun extends StatelessWidget {
  const CurrentRun({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      appBar: AppBar(
        title: const Text('Current Run'),
        backgroundColor: Colors.teal,
      ),
      body: const Map(),
    );
  }
}
*/

class CurrentRun extends ConsumerStatefulWidget {
  const CurrentRun({super.key});

  @override
  ConsumerState<CurrentRun> createState() => _CurrentRunState();
}

class _CurrentRunState extends ConsumerState<CurrentRun> {
  //error here: 'CurrentRun' doesn't conform to the bound 'ConsumerStatefulWidget' of the type parameter 'T'. Try using a type that is or is a subclass of 'ConsumerStatefulWidget'.darttype_argument_not_matching_bounds.
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsedTime = '00:00:00';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = _formatDuration(_stopwatch.elapsed);
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
    _stopwatch.stop();
    _timer?.cancel();
    // Add code to save the run data, show a summary, etc.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run Completed'),
        content: Text('Your run lasted $_elapsedTime'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to home screen
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final speed = ref.watch(speedProvider);

    return Scaffold(
      backgroundColor: Colors.teal,
      appBar: AppBar(
        title: const Text('Current Run'),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                const SizedBox(
                  height: 500,
                  child: Map(),
                ), // This will fill the entire expanded area
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
                      _elapsedTime,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 235, 121, 79),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  //Added speed from the new speed variable that borrows
                  child: Text(
                    'Speed: ${speed.toStringAsFixed(2)} mph',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 235, 121, 79)
                        .withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _elapsedTime,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
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
