import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'temp_goal_providers.dart';
import 'custom_distance_provider.dart';
import 'custom_pace_provider.dart';
import 'readable_pace_provider.dart';
import 'distance_unit_provider.dart';

enum GoalType {
  none, // No goal set
  distanceOnly, // Just distance (e.g., "Run 5 km")
  timeOnly, // Just time (e.g., "Run 30 min")
  distanceAndTime // Distance under time (e.g., "Run 5 km under 30 min")
}

// Provider que determina automáticamente el tipo de objetivo basado en las selecciones
final goalTypeProvider = Provider<GoalType>((ref) {
  final tempDistance = ref.watch(tempSelectedDistanceProvider);
  final tempTime = ref.watch(tempSelectedTimeProvider);
  final hasActiveGoal = ref.watch(customDistanceProvider) != null &&
      ref.watch(customPaceProvider) != null;

  // Si ya hay un goal activo, no mostrar tipo basado en temp selections
  if (hasActiveGoal) {
    return GoalType.none; // Will be handled differently for active goals
  }

  if (tempDistance != null && tempTime != null) {
    return GoalType.distanceAndTime;
  } else if (tempDistance != null) {
    return GoalType.distanceOnly;
  } else if (tempTime != null) {
    return GoalType.timeOnly;
  } else {
    return GoalType.none;
  }
});

// Provider para el mensaje dinámico del objetivo
final goalMessageProvider = Provider<String>((ref) {
  final goalType = ref.watch(goalTypeProvider);
  final tempDistance = ref.watch(tempSelectedDistanceProvider);
  final tempTime = ref.watch(tempSelectedTimeProvider);
  final unit = ref.watch(distanceUnitProvider);
  final hasActiveGoal = ref.watch(customDistanceProvider) != null &&
      ref.watch(customPaceProvider) != null;

  // Si hay objetivo activo, mostrar el objetivo existente
  if (hasActiveGoal) {
    final readableGoal = ref.watch(readablePaceProvider);
    if (readableGoal.isNotEmpty) {
      return readableGoal.replaceFirst(' in ', ' under ');
    }
  }

  final unitLabel = unit == DistanceUnit.kilometers ? 'km' : 'mi';

  switch (goalType) {
    case GoalType.distanceOnly:
      return '${tempDistance!.toStringAsFixed(1)} $unitLabel';
    case GoalType.timeOnly:
      return '${_formatDurationSimple(tempTime!)}';
    case GoalType.distanceAndTime:
      return '${tempDistance!.toStringAsFixed(1)} $unitLabel under ${_formatDurationSimple(tempTime!)}';
    case GoalType.none:
      return 'Choose distance, time, or both';
  }
});

String _formatDurationSimple(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;

  if (hours > 0) {
    if (minutes > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${hours}h';
    }
  } else if (minutes > 0) {
    if (seconds > 0 && minutes < 5) {
      // Show seconds only for short durations
      return '${minutes}m ${seconds}s';
    } else {
      return '${minutes}m';
    }
  } else {
    return '${seconds}s';
  }
}
