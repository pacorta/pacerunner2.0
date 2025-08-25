import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'custom_distance_provider.dart';
import 'custom_pace_provider.dart';
import 'readable_pace_provider.dart';

// Providers para el estado temporal del goal input
// Estos se usan para comunicar entre InlineGoalInput y HomeScreen

final tempSelectedDistanceProvider = StateProvider<double?>((ref) => null);
final tempSelectedTimeProvider =
    StateProvider<Duration?>((ref) => null); // No default time

// Provider que determina si el usuario tiene selecciones pendientes
final hasUnconfirmedGoalProvider = Provider<bool>((ref) {
  final tempDistance = ref.watch(tempSelectedDistanceProvider);
  final tempTime = ref.watch(tempSelectedTimeProvider);
  final hasActiveGoal = ref.watch(customDistanceProvider) != null ||
      ref.watch(customPaceProvider) != null ||
      ref.watch(readablePaceProvider).isNotEmpty;

  // True si tiene AL MENOS distancia O tiempo seleccionados pero no goal activo
  return (tempDistance != null || tempTime != null) && !hasActiveGoal;
});
