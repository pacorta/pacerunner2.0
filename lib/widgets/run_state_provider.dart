import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Estados posibles del run
enum RunState {
  fetchingGPS, // Buscando señal GPS inicial
  readyToStart, // GPS listo, esperando que usuario presione "Start Run"
  running, // Corriendo activamente (cronometro + GPS counting)
  paused, // Pausado (cronometro parado, GPS no cuenta, pero datos guardados)
  finished // Run completado (terminado permanentemente)
}

// Provider principal para el estado del run
final runStateProvider = StateProvider<RunState>((ref) => RunState.fetchingGPS);

// helper: Estamos buscando GPS?
final isFetchingGPSProvider = Provider<bool>((ref) {
  final runState = ref.watch(runStateProvider);
  return runState == RunState.fetchingGPS;
});

// helper: Esta listo para empezar?
final isReadyToStartProvider = Provider<bool>((ref) {
  final runState = ref.watch(runStateProvider);
  return runState == RunState.readyToStart;
});

// helper: Deberiamos trackear distancia y pace?
final shouldTrackDataProvider = Provider<bool>((ref) {
  final runState = ref.watch(runStateProvider);
  return runState == RunState.running; // Solo cuando esta "running"
});

// helper: Esta el cronometro activo?
final isTimerActiveProvider = Provider<bool>((ref) {
  final runState = ref.watch(runStateProvider);
  return runState == RunState.running; // Solo cuando esta "running"
});

// helper: Puede el usuario hacer START?
final canStartProvider = Provider<bool>((ref) {
  final runState = ref.watch(runStateProvider);
  return runState == RunState.readyToStart;
});

// helper: Puede el usuario hacer pause?
final canPauseProvider = Provider<bool>((ref) {
  final runState = ref.watch(runStateProvider);
  return runState == RunState.running; // Solo se puede pausar si esta corriendo
});

// helper: Puede el usuario hacer resume?
final canResumeProvider = Provider<bool>((ref) {
  final runState = ref.watch(runStateProvider);
  return runState == RunState.paused; // Solo se puede resumir si esta pausado
});

// helper: Puede el usuario terminar el run?
final canFinishProvider = Provider<bool>((ref) {
  final runState = ref.watch(runStateProvider);
  return runState == RunState.running ||
      runState ==
          RunState.paused; // Se puede terminar si esta corriendo o pausado
});

// helper: Texto para mostrar en UI
String getRunStateText(RunState state) {
  switch (state) {
    case RunState.fetchingGPS:
      return 'Getting GPS Signal...';
    case RunState.readyToStart:
      return 'Ready to Start';
    case RunState.running:
      return 'Running';
    case RunState.paused:
      return 'Paused';
    case RunState.finished:
      return 'Finished';
  }
}

// helper: Iconos para UI
IconData getRunStateIcon(RunState state) {
  switch (state) {
    case RunState.fetchingGPS:
      return Icons.gps_not_fixed;
    case RunState.readyToStart:
      return Icons.play_arrow;
    case RunState.running:
      return Icons.pause;
    case RunState.paused:
      return Icons.play_arrow;
    case RunState.finished:
      return Icons.stop;
  }
}

// helper: Color para mostrar en UI
Color getRunStateColor(RunState state) {
  switch (state) {
    case RunState.fetchingGPS:
      return Colors.orange;
    case RunState.readyToStart:
      return Colors.green;
    case RunState.running:
      return Colors.blue;
    case RunState.paused:
      return Colors.amber;
    case RunState.finished:
      return Colors.grey;
  }
}
