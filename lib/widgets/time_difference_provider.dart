import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'projected_finish_provider.dart';

/// Time difference (segundos) entre el tiempo proyectado y el tiempo objetivo.
/// - Positive value: user is behind schedule (slower than target)
/// - Zero or negative: user is on track or ahead of schedule
///
final timeDifferenceSecondsProvider = Provider<int?>((ref) {
  final projection = ref.watch(projectedFinishProvider);
  final differenceString = projection["difference"];

  if (differenceString == null) {
    return null;
  }

  final asNumber = double.tryParse(differenceString);
  if (asNumber == null) {
    return null;
  }

  return asNumber.round();
});
