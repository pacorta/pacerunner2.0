import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'projected_finish_provider.dart';

class PredictionDisplay extends ConsumerWidget {
  const PredictionDisplay({super.key});

  // Helper function to determine text color based on projection vs target
  Color _getProjectionColor(Map<String, String> prediction) {
    final difference = prediction['difference'];
    if (difference == null || difference == '0') {
      return Colors.white; // Default color for calculating/starting
    }

    final diffValue = double.tryParse(difference);
    if (diffValue == null) {
      return Colors.white; // Default color if parsing fails
    }

    if (diffValue > 0) {
      // User is slower than target - show in red
      return Colors.red;
    } else {
      // User is faster than target - show in white
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prediction = ref.watch(projectedFinishProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Projected Time
          Text(
            'Projected finish time',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),

          Text(
            prediction['projectedTime'] ?? 'Keep running...',
            style: TextStyle(
              color: _getProjectionColor(prediction),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),

          /*
          // Status Message -- just in case.
          Text(
            prediction['status'] ?? 'Starting...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          */
        ],
      ),
    );
  }
}
