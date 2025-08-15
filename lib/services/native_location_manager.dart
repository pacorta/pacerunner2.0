import 'package:flutter/services.dart';

class NativeLocationManager {
  static const MethodChannel _channel =
      MethodChannel('pacebud/location_manager');

  /// Configure iOS location manager for fitness tracking with native settings:
  /// - activityType = .fitness
  /// - allowsBackgroundLocationUpdates = true
  /// - pausesLocationUpdatesAutomatically = false
  /// - showsBackgroundLocationIndicator = true (iOS 11+)
  static Future<bool> configureForFitness() async {
    try {
      final result = await _channel.invokeMethod('configureForFitness');
      return result == true;
    } on PlatformException catch (e) {
      print(
          'NativeLocationManager: Error configuring for fitness: ${e.message}');
      return false;
    }
  }

  /// Enable background location updates with iOS native settings
  static Future<bool> enableBackgroundLocation() async {
    try {
      final result = await _channel.invokeMethod('enableBackgroundLocation');
      return result == true;
    } on PlatformException catch (e) {
      print(
          'NativeLocationManager: Error enabling background location: ${e.message}');
      return false;
    }
  }

  /// Disable background location updates
  static Future<bool> disableBackgroundLocation() async {
    try {
      final result = await _channel.invokeMethod('disableBackgroundLocation');
      return result == true;
    } on PlatformException catch (e) {
      print(
          'NativeLocationManager: Error disabling background location: ${e.message}');
      return false;
    }
  }

  /// Get the real iOS authorization status (distinguishes between Always and When In Use)
  static Future<String> authorizationStatus() async {
    try {
      return await _channel.invokeMethod<String>('authorizationStatus') ??
          'unknown';
    } on PlatformException catch (e) {
      print(
          'NativeLocationManager: Error getting authorization status: ${e.message}');
      return 'unknown';
    }
  }

  /// Request Always authorization (shows the second iOS prompt if user has When In Use)
  static Future<void> requestAlways() async {
    try {
      await _channel.invokeMethod('requestAlways');
    } on PlatformException catch (e) {
      print('NativeLocationManager: requestAlways error: ${e.message}');
    }
  }
}
