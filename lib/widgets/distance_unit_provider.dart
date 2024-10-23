//provider for the distance unit preference, part of the #km2miles update.
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DistanceUnit { kilometers, miles }

final distanceUnitProvider =
    StateProvider<DistanceUnit>((ref) => DistanceUnit.kilometers);
