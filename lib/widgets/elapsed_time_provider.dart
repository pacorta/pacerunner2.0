import 'package:flutter_riverpod/flutter_riverpod.dart';

final elapsedTimeProvider = StateProvider<String>((ref) => '00:00:00');

final elapsedTimeProviderInSeconds = Provider<double>((ref) {
  final timeString = ref.watch(elapsedTimeProvider);
  final parts = timeString.split(':');
  return double.parse(parts[0]) * 3600 +
      double.parse(parts[1]) * 60 +
      double.parse(parts[2]);
});
