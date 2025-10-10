//provider for the distance unit preference, part of the #km2miles update.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DistanceUnit { kilometers, miles }

// StateNotifier that persists to SharedPreferences
class DistanceUnitNotifier extends StateNotifier<DistanceUnit> {
  static const String _key = 'distance_unit_preference';

  DistanceUnitNotifier() : super(DistanceUnit.kilometers) {
    _loadPreference();
  }

  // Load saved preference on init
  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved == 'miles') {
        state = DistanceUnit.miles;
      } else {
        state = DistanceUnit.kilometers;
      }
    } catch (e) {
      // If load fails, keep default (kilometers)
      print('Error loading distance unit preference: $e');
    }
  }

  // Update state and persist
  Future<void> setUnit(DistanceUnit unit) async {
    state = unit;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        unit == DistanceUnit.miles ? 'miles' : 'kilometers',
      );
    } catch (e) {
      print('Error saving distance unit preference: $e');
    }
  }
}

final distanceUnitProvider =
    StateNotifierProvider<DistanceUnitNotifier, DistanceUnit>(
        (ref) => DistanceUnitNotifier());
