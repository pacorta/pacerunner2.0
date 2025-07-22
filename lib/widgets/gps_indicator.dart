import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gps_status_provider.dart';

class GPSIndicator extends ConsumerWidget {
  const GPSIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gpsStatus = ref.watch(gpsStatusProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'GPS',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: getGPSStatusColor(gpsStatus),
        ),
      ),
    );
  }
}
