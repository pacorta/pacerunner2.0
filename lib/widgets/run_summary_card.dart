import 'package:flutter/material.dart';
import 'dart:typed_data';

class RunSummaryCard extends StatelessWidget {
  final Uint8List? mapSnapshot;
  final String distance;
  final String pace;
  final String time;
  final String distanceUnit;

  const RunSummaryCard({
    super.key,
    this.mapSnapshot,
    required this.distance,
    required this.pace,
    required this.time,
    required this.distanceUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
            Colors.black.withOpacity(0.8), // Dark semi-transparent background
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Map screenshot (smaller size)
          if (mapSnapshot != null) ...[
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  mapSnapshot!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.withOpacity(0.3),
                      child: const Center(
                        child: Text(
                          'Map preview unavailable',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Metrics - stacked vertically and centered
          Column(
            children: [
              _buildMetric('Distance', '$distance $distanceUnit'),
              const SizedBox(height: 16),
              _buildMetric('Pace', pace),
              const SizedBox(height: 16),
              _buildMetric('Time', time),
            ],
          ),

          const SizedBox(height: 32),

          // Pacebud horizontal white logo
          Image.asset(
            'images/pacebud-horizontal-white.png',
            height: 32,
            errorBuilder: (context, error, stackTrace) {
              return const Text(
                'pacebud',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    // Format time if this is the Time metric (consistent with running_stats.dart)
    String displayValue = value;
    if (label == 'Time' && value.contains(':')) {
      displayValue = _formatRunTime(value);
    }

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          displayValue,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Time formatting function (copied from running_stats.dart)
  String _formatRunTime(String timeString) {
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
}
