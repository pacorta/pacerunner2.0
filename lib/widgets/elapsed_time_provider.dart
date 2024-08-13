//#pace
import 'package:flutter_riverpod/flutter_riverpod.dart';

final elapsedTimeProvider = StateProvider<String>((ref) => '00:00:00');

final elapsedTimeProviderInSeconds = Provider<int>((ref) {
  final timeString = ref.watch(elapsedTimeProvider);
  final parts = timeString.split(':');
  return int.parse(parts[0]) * 3600 +
      int.parse(parts[1]) * 60 +
      int.parse(parts[2]);
});
