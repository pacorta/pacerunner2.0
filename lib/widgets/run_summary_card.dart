import 'package:flutter/material.dart';
import 'dart:typed_data';

class RunSummaryCard extends StatelessWidget {
  final Uint8List? mapSnapshot;
  final String distance;
  final String pace;
  final String time;
  final String distanceUnit;
  // When false, the card renders without the semi-transparent rounded
  // rectangle so the exported image can be pasted over photos.
  final bool showCardBackground;

  const RunSummaryCard({
    super.key,
    this.mapSnapshot,
    required this.distance,
    required this.pace,
    required this.time,
    required this.distanceUnit,
    this.showCardBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    const double contentWidth = 240; // keep all elements visually aligned

    final Widget content = SizedBox(
        width: contentWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mapSnapshot != null) ...[
              SizedBox(
                width: 160,
                height: 88,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(
                    mapSnapshot!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.withOpacity(0.3),
                        child: const Center(
                          child: Text(
                            'Map preview',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Column(
              children: [
                _buildMetric('Distance', '$distance $distanceUnit'),
                const SizedBox(height: 10),
                _buildMetric('Pace', pace),
                const SizedBox(height: 10),
                _buildMetric('Time', time),
              ],
            ),
            const SizedBox(height: 5),
            Image.asset(
              'images/pacebud-horizontal-white.png',
              width: 160,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Text(
                  'pacebud',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ],
        ));

    if (!showCardBackground) {
      // Export variant without background rectangle
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
        child: Center(child: content),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(28),
      ),
      child: content,
    );
  }

  Widget _buildMetric(String label, String value) {
    String displayValue = value;
    if (label == 'Time' && value.contains(':')) {
      displayValue = _formatRunTime(value);
    }
    if (label == 'Pace') {
      // Ensure a space before the slash so it reads like "8:36 /mi"
      if (!displayValue.contains(' /')) {
        displayValue = displayValue.replaceAll('/', ' /');
      }
    }

    final double valueFontSize = label == 'Distance' ? 48 : 40;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 20,
            fontWeight: FontWeight.w500,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          displayValue,
          style: TextStyle(
            color: Colors.white,
            fontSize: valueFontSize,
            fontWeight: FontWeight.w700,
            height: 1.05,
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
