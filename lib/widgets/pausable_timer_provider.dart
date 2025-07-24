import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

// Clase para manejar un cronómetro que se puede pausar
class PausableTimer {
  Duration _accumulatedTime = Duration.zero; // Tiempo total acumulado
  DateTime? _sessionStartTime; // Cuándo empezó la sesión actual
  Timer? _timer; // Timer de Flutter
  bool _isRunning = false; // ¿Está corriendo actualmente?

  // Callback que se llama cada segundo
  Function(Duration)? _onTick;

  Duration get elapsedTime {
    if (_isRunning && _sessionStartTime != null) {
      // Si está corriendo, tiempo = acumulado + tiempo de sesión actual
      return _accumulatedTime + DateTime.now().difference(_sessionStartTime!);
    } else {
      // Si está parado, solo el tiempo acumulado
      return _accumulatedTime;
    }
  }

  bool get isRunning => _isRunning;

  // Empezar el cronómetro
  void start(Function(Duration) onTick) {
    if (_isRunning) return; // Ya está corriendo

    _onTick = onTick;
    _sessionStartTime = DateTime.now();
    _isRunning = true;

    // Timer que se ejecuta cada segundo
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_onTick != null) {
        _onTick!(elapsedTime);
      }
    });
  }

  // Pausar el cronómetro
  void pause() {
    if (!_isRunning) return; // Ya está parado

    // Guardar el tiempo de esta sesión
    if (_sessionStartTime != null) {
      _accumulatedTime += DateTime.now().difference(_sessionStartTime!);
    }

    // Parar todo
    _timer?.cancel();
    _timer = null;
    _sessionStartTime = null;
    _isRunning = false;
  }

  // Resumir el cronómetro (igual que start)
  void resume(Function(Duration) onTick) {
    start(onTick); // Reutilizamos start()
  }

  // Parar completamente y resetear
  void stop() {
    _timer?.cancel();
    _timer = null;
    _sessionStartTime = null;
    _isRunning = false;
    _accumulatedTime = Duration.zero; // Reset completo
  }

  // Cleanup
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

// Provider para el cronómetro pausable
final pausableTimerProvider =
    StateNotifierProvider<PausableTimerNotifier, Duration>((ref) {
  return PausableTimerNotifier();
});

// Notifier que maneja el estado del cronómetro
class PausableTimerNotifier extends StateNotifier<Duration> {
  final PausableTimer _timer = PausableTimer();

  PausableTimerNotifier() : super(Duration.zero);

  // Empezar cronómetro
  void start() {
    _timer.start((duration) {
      state = duration; // Actualizar estado cada segundo
    });
  }

  // Pausar cronómetro
  void pause() {
    _timer.pause();
    state = _timer.elapsedTime; // Actualizar estado final
  }

  // Resumir cronómetro
  void resume() {
    _timer.resume((duration) {
      state = duration; // Actualizar estado cada segundo
    });
  }

  // Parar y resetear cronómetro
  void stop() {
    _timer.stop();
    state = Duration.zero; // Reset estado
  }

  bool get isRunning => _timer.isRunning;

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }
}

// Helper provider: Tiempo formateado como string
final formattedElapsedTimeProvider = Provider<String>((ref) {
  final duration = ref.watch(pausableTimerProvider);
  return formatDuration(duration);
});

// Helper function: Formatear Duration como "HH:MM:SS"
String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");

  String hours = twoDigits(duration.inHours);
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));

  return "$hours:$minutes:$seconds";
}

// Helper provider: Tiempo en segundos totales (para pace calculations)
final elapsedTimeInSecondsProvider = Provider<double>((ref) {
  final duration = ref.watch(pausableTimerProvider);
  return duration.inSeconds.toDouble();
});
