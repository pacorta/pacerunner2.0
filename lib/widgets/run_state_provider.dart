import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Estados posibles del run
enum RunState {
  notStarted, // Usuario no ha empezado a correr
  running, // Corriendo activamente (cronómetro + GPS counting)
  paused, // Pausado (cronometro parado, GPS no cuenta, pero datos guardados)
  finished // Run completado (terminado permanentemente)
}

// Provider principal para el estado del run
final runStateProvider = StateProvider<RunState>((ref) => RunState.notStarted);

// Helper: ¿Deberíamos trackear distancia y pace?
final shouldTrackDataProvider = Provider<bool>((ref) {
  final runState = ref.watch(runStateProvider);
  return runState == RunState.running; // Solo cuando está "running"
});

// Helper: ¿Está el cronómetro activo?
final isTimerActiveProvider = Provider<bool>((ref) {
  final runState = ref.watch(runStateProvider);
  return runState == RunState.running; // Solo cuando está "running"
});

// Helper: ¿Puede el usuario hacer pause?
final canPauseProvider = Provider<bool>((ref) {
  final runState = ref.watch(runStateProvider);
  return runState == RunState.running; // Solo se puede pausar si está corriendo
});

// Helper: ¿Puede el usuario hacer resume?
final canResumeProvider = Provider<bool>((ref) {
  final runState = ref.watch(runStateProvider);
  return runState == RunState.paused; // Solo se puede resumir si está pausado
});

// Helper: ¿Puede el usuario empezar?
final canStartProvider = Provider<bool>((ref) {
  final runState = ref.watch(runStateProvider);
  return runState ==
      RunState.notStarted; // Solo se puede empezar si no ha empezado
});

// Helper: ¿Puede el usuario terminar el run?
final canFinishProvider = Provider<bool>((ref) {
  final runState = ref.watch(runStateProvider);
  return runState == RunState.running ||
      runState ==
          RunState.paused; // Se puede terminar si está corriendo o pausado
});

// Helper: Texto para mostrar en UI
String getRunStateText(RunState state) {
  switch (state) {
    case RunState.notStarted:
      return 'Ready to Start';
    case RunState.running:
      return 'Running';
    case RunState.paused:
      return 'Paused';
    case RunState.finished:
      return 'Finished';
  }
}

IconData getRunStateIcon(RunState state) {
  switch (state) {
    case RunState.notStarted:
      return Icons.play_arrow;
    case RunState.running:
      return Icons.pause;
    case RunState.paused:
      return Icons.play_arrow;
    case RunState.finished:
      return Icons.stop;
  }
}

// Helper: Color para mostrar en UI
Color getRunStateColor(RunState state) {
  switch (state) {
    case RunState.notStarted:
      return Colors.green;
    case RunState.running:
      return Colors.orange;
    case RunState.paused:
      return Colors.blue;
    case RunState.finished:
      return Colors.red;
  }
}
