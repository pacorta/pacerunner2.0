import 'package:flutter/services.dart';

class LiveActivityService {
  static const MethodChannel _channel = MethodChannel('pacebud/live_activity');

  /// Start a live activity for running session
  static Future<bool> startRunningActivity() async {
    try {
      final result = await _channel.invokeMethod('startRunningActivity');
      return result == true;
    } on PlatformException catch (e) {
      print('LiveActivityService: Error starting activity: ${e.message}');
      return false;
    }
  }

  /// Update the live activity with current running data
  static Future<bool> updateRunningActivity({
    required double distance,
    required String distanceUnit,
    required String elapsedTime,
    required String pace,
    required bool isRunning,
    String? goal,
    String? predictedFinish,
    int? differenceSeconds,
    double? progress,
    String? progressKind,
    String? progressLabel,
  }) async {
    try {
      final result = await _channel.invokeMethod('updateRunningActivity', {
        'distance': distance,
        'distanceUnit': distanceUnit,
        'elapsedTime': elapsedTime,
        'pace': pace,
        'isRunning': isRunning,
        'goal': goal,
        'predictedFinish': predictedFinish,
        'differenceSeconds': differenceSeconds,
        'progress': progress,
        'progressKind': progressKind,
        'progressLabel': progressLabel,
      });
      return result == true;
    } on PlatformException catch (e) {
      print('LiveActivityService: Error updating activity: ${e.message}');
      return false;
    }
  }

  /// End the live activity
  static Future<bool> endRunningActivity() async {
    try {
      final result = await _channel.invokeMethod('endRunningActivity');
      return result == true;
    } on PlatformException catch (e) {
      print('LiveActivityService: Error ending activity: ${e.message}');
      return false;
    }
  }

  /// Check if Live Activities are available on this device
  static Future<bool> areActivitiesAvailable() async {
    try {
      final result = await _channel.invokeMethod('areActivitiesAvailable');
      return result == true;
    } on PlatformException catch (e) {
      print('LiveActivityService: Error checking availability: ${e.message}');
      return false;
    }
  }
}
