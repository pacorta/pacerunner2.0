import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'distance_unit_provider.dart';

//in other files known as "distanceUnitString"
//tested and works [nov 20, 2024]

final formattedUnitString = Provider<String>((ref) {
  final unit = ref.watch(distanceUnitProvider);

  if (unit == DistanceUnit.kilometers) {
    return 'km';
  }
  if (unit == DistanceUnit.miles) {
    return 'mi';
  } else {
    return 'km/mi';
  }
});
