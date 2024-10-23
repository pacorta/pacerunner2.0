import 'package:flutter/material.dart';
import 'speed_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//Checking how to pass this value here, just testing my knowledge

class Results extends ConsumerStatefulWidget {
  const Results({super.key});

  @override
  ConsumerState<Results> createState() => _ResultsState();
}

class _ResultsState extends ConsumerState<Results> {
  @override
  Widget build(BuildContext context) {
    final speed = ref.watch(speedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Completed!'),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(10.0),
          color: const Color.fromARGB(255, 54, 216, 189),
          transform: Matrix4.rotationZ(0.4),
          child: Text('Current Speed: ${speed.toStringAsFixed(2)}'),
        ),
      ),
    );
  }
}
