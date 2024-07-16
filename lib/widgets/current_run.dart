import 'package:flutter/material.dart';
import 'map.dart';

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
