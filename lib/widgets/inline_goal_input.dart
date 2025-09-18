import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'distance_unit_provider.dart';
import 'custom_distance_provider.dart';
import 'custom_pace_provider.dart';
import 'readable_pace_provider.dart';
import 'temp_goal_providers.dart';
import 'cupertino_duration_picker.dart';
import 'cupertino_distance_picker.dart';
import 'goal_type_provider.dart';
import 'time_goal_provider.dart';

class InlineGoalInput extends ConsumerStatefulWidget {
  const InlineGoalInput({super.key});

  @override
  ConsumerState<InlineGoalInput> createState() => _InlineGoalInputState();
}

// Validación de objetivos para los 3 tipos
bool _isValidGoal(double? distance, Duration? time, DistanceUnit unit) {
  // Must have at least one selection
  if (distance == null && time == null) return false;

  // Validate distance if provided
  if (distance != null && distance < 1.0) return false;

  // Validate time if provided
  if (time != null && time.inSeconds < 60) return false;

  return true;
}

String _getValidationMessage(
    double? distance, Duration? time, DistanceUnit unit) {
  if (distance == null && time == null) {
    return 'Select at least distance or time';
  }

  final unitLabel = unit == DistanceUnit.kilometers ? 'km' : 'mi';

  if (distance != null && distance < 1.0) {
    return 'Distance must be at least 1 $unitLabel';
  }

  if (time != null && time.inSeconds < 60) {
    return 'Time must be at least 1 minute';
  }

  return '';
}

// Función global para establecer el goal desde HomeScreen
void setGoalFromTempSelections(WidgetRef ref, BuildContext context) {
  final selectedDistance = ref.read(tempSelectedDistanceProvider);
  final selectedTime = ref.read(tempSelectedTimeProvider);
  final unit = ref.read(distanceUnitProvider);

  // Validar objetivo
  if (!_isValidGoal(selectedDistance, selectedTime, unit)) {
    final message = _getValidationMessage(selectedDistance, selectedTime, unit);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    return;
  }

  // Determine goal type and set appropriate values
  if (selectedDistance != null && selectedTime != null) {
    // Distance + Time goal: Calculate pace
    double paceInSeconds = selectedTime.inSeconds / selectedDistance;
    ref.read(customDistanceProvider.notifier).state = selectedDistance;
    ref.read(customPaceProvider.notifier).state = paceInSeconds;

    String readablePace =
        _formatReadablePaceGlobal(selectedDistance, selectedTime, unit);
    ref.read(readablePaceProvider.notifier).state = readablePace;
  } else if (selectedDistance != null) {
    // Distance-only goal
    ref.read(customDistanceProvider.notifier).state = selectedDistance;
    ref.read(customPaceProvider.notifier).state = null; // No pace target
    ref.read(timeOnlyGoalSecondsProvider.notifier).state =
        null; // clear time-only

    final unitLabel = unit == DistanceUnit.kilometers ? 'km' : 'mi';
    ref.read(readablePaceProvider.notifier).state =
        'Run ${selectedDistance.toStringAsFixed(1)} $unitLabel';
  } else if (selectedTime != null) {
    // Time-only goal
    ref.read(customDistanceProvider.notifier).state =
        null; // No distance target
    ref.read(customPaceProvider.notifier).state = null; // No pace target
    ref.read(timeOnlyGoalSecondsProvider.notifier).state =
        selectedTime.inSeconds.toDouble();

    ref.read(readablePaceProvider.notifier).state =
        'Run ${_formatDurationSimpleGlobal(selectedTime)}';
  }
}

// Función global para limpiar TODO el estado relacionado al goal
// Úsala al finalizar o descartar una corrida para que Home quede sin objetivo activo
void clearGoalProviders(WidgetRef ref) {
  // Limpiar selecciones temporales del input
  ref.read(tempSelectedDistanceProvider.notifier).state = null;
  ref.read(tempSelectedTimeProvider.notifier).state = null;

  // Limpiar objetivo activo (distance/pace) y su texto legible
  ref.read(customDistanceProvider.notifier).state = null;
  ref.read(customPaceProvider.notifier).state = null;
  ref.read(readablePaceProvider.notifier).state = '';
}

String _formatReadablePaceGlobal(
    double distance, Duration duration, DistanceUnit unit) {
  final unitLabel = unit == DistanceUnit.kilometers ? 'km' : 'mi';
  String timeFormatted;

  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;

  if (hours > 0) {
    if (minutes > 0) {
      timeFormatted = '${hours}h ${minutes}m';
    } else {
      timeFormatted = '${hours}h';
    }
  } else if (minutes > 0) {
    if (seconds > 0) {
      timeFormatted = '${minutes}m ${seconds}s';
    } else {
      timeFormatted = '${minutes}m';
    }
  } else {
    timeFormatted = '${seconds}s';
  }

  return '${distance.toStringAsFixed(1)} $unitLabel under $timeFormatted';
}

String _formatDurationSimpleGlobal(Duration duration) {
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

class _InlineGoalInputState extends ConsumerState<InlineGoalInput>
    with TickerProviderStateMixin {
  // Shake controllers for guiding the user to tap the other field
  late final AnimationController _distanceShakeController;
  late final AnimationController _timeShakeController;

  @override
  void initState() {
    super.initState();
    // Init shake controllers
    _distanceShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _timeShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    // Initialize with existing goal if set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existingDistance = ref.read(customDistanceProvider);
      if (existingDistance != null) {
        ref.read(tempSelectedDistanceProvider.notifier).state =
            existingDistance;
      }
    });
  }

  @override
  void dispose() {
    _distanceShakeController.dispose();
    _timeShakeController.dispose();
    super.dispose();
  }

  void _clearGoal() {
    ref.read(tempSelectedDistanceProvider.notifier).state = null;
    ref.read(tempSelectedTimeProvider.notifier).state = null;
    ref.read(customDistanceProvider.notifier).state = null;
    ref.read(customPaceProvider.notifier).state = null;
    ref.read(timeOnlyGoalSecondsProvider.notifier).state = null;
    ref.read(readablePaceProvider.notifier).state = '';
  }

  Future<void> _showGoalHelpDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Set Your Goal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose how you want to track your run:',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF34495E),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              // Option 1: Distance only
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.straighten,
                      size: 20, color: Color(0xFF2C3E50)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style:
                            TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
                        children: [
                          TextSpan(
                            text: 'Distance only: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: 'Set just the '),
                          TextSpan(
                            text: 'distance',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B59B6),
                            ),
                          ),
                          TextSpan(text: ' you want to run'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Option 2: Time only
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.access_time,
                      size: 20, color: Color(0xFF2C3E50)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style:
                            TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
                        children: [
                          TextSpan(
                            text: 'Time only: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: 'Set just the '),
                          TextSpan(
                            text: 'time',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B59B6),
                            ),
                          ),
                          TextSpan(text: ' you want to run'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Option 3: Both distance and time
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.speed, size: 20, color: Color(0xFF2C3E50)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style:
                            TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
                        children: [
                          TextSpan(
                            text: 'Distance + Time: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: 'Set '),
                          TextSpan(
                            text: 'both',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B59B6),
                            ),
                          ),
                          TextSpan(
                              text:
                                  ' for a pace challenge. Beat your projection!'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates_outlined,
                        size: 18, color: Color(0xFF3498DB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap the numbers to change them, or leave at 0 to skip that goal.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF9B59B6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Let\'s run!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.all(16),
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Riverpod listeners to trigger shakes when only one of the two is set
    ref.listen<double?>(tempSelectedDistanceProvider, (previous, next) {
      final time = ref.read(tempSelectedTimeProvider);
      if (next != null && time == null) {
        _nudge(_timeShakeController,
            () => ref.read(tempSelectedTimeProvider) == null);
      }
    });

    ref.listen<Duration?>(tempSelectedTimeProvider, (previous, next) {
      final distance = ref.read(tempSelectedDistanceProvider);
      if (next != null && distance == null) {
        _nudge(_distanceShakeController,
            () => ref.read(tempSelectedDistanceProvider) == null);
      }
    });

    final unit = ref.watch(distanceUnitProvider);
    final unitLabel = unit == DistanceUnit.kilometers ? 'km' : 'mi';
    final selectedDistance = ref.watch(tempSelectedDistanceProvider);
    final selectedTime = ref.watch(tempSelectedTimeProvider);
    final goalMessage = ref.watch(goalMessageProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Set Goal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _showGoalHelpDialog,
                    icon: Icon(Icons.help_outline,
                        color: Colors.grey.shade600, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'How it works',
                  ),
                  if (selectedDistance != null || selectedTime != null)
                    GestureDetector(
                      onTap: _clearGoal,
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Dynamic goal message
          Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Text(
              goalMessage,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: goalMessage == 'Choose distance, time, or both'
                    ? Colors.grey.shade600
                    : const Color.fromRGBO(140, 82, 255, 1.0),
              ),
            ),
          ),

          const SizedBox(height: 2),

          // Three data segments
          Row(
            children: [
              // Distance segment
              Expanded(
                flex: 2,
                child: _wrapShake(
                  controller: _distanceShakeController,
                  child: _buildDataSegment(
                    label: 'Distance',
                    value: selectedDistance?.toStringAsFixed(1) ?? '0',
                    onTap: () => _showDistanceSelector(),
                    isActive: selectedDistance != null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Unit segment
              Expanded(
                flex: 1,
                child: _buildDataSegment(
                  label: 'Unit',
                  value: unitLabel,
                  onTap: () => _toggleUnit(),
                  isActive: true, // Unit is always active
                ),
              ),
              const SizedBox(width: 8),

              // Time segment
              Expanded(
                flex: 2,
                child: _wrapShake(
                  controller: _timeShakeController,
                  child: _buildDataSegment(
                    label: 'Time',
                    value: _formatTime(selectedTime),
                    onTap: () => _showTimeSelector(),
                    isActive: selectedTime != null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataSegment({
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isActive, // New parameter for opacity feedback
  }) {
    final baseColor = const Color.fromRGBO(140, 82, 255, 1.0);
    final opacity = isActive ? 1.0 : 0.4;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: baseColor.withOpacity(opacity),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toLowerCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Wrap a child with a horizontal shake animation
  Widget _wrapShake({
    required AnimationController controller,
    required Widget child,
  }) {
    // A small oscillation on X axis
    final Animation<double> offset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5, end: -5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5, end: 3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 3, end: -2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -2, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    return AnimatedBuilder(
      animation: controller,
      builder: (context, childWidget) {
        return Transform.translate(
          offset: Offset(offset.value, 0),
          child: childWidget,
        );
      },
      child: child,
    );
  }

  // Trigger a few subtle shakes separated by pauses while the predicate remains true
  Future<void> _nudge(
      AnimationController controller, bool Function() shouldContinue) async {
    // Run up to 3 times, stop early if condition no longer holds
    for (int i = 0; i < 3; i++) {
      if (!shouldContinue()) return;
      await controller.forward(from: 0);
      if (!shouldContinue()) return;
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  void _toggleUnit() {
    final currentUnit = ref.read(distanceUnitProvider);
    final newUnit = currentUnit == DistanceUnit.kilometers
        ? DistanceUnit.miles
        : DistanceUnit.kilometers;

    ref.read(distanceUnitProvider.notifier).state = newUnit;

    // Convert existing distance if set
    final selectedDistance = ref.read(tempSelectedDistanceProvider);
    if (selectedDistance != null) {
      double newDistance;
      if (newUnit == DistanceUnit.miles &&
          currentUnit == DistanceUnit.kilometers) {
        newDistance = selectedDistance * 0.621371; // km to miles
      } else if (newUnit == DistanceUnit.kilometers &&
          currentUnit == DistanceUnit.miles) {
        newDistance = selectedDistance / 0.621371; // miles to km
      } else {
        newDistance = selectedDistance;
      }
      ref.read(tempSelectedDistanceProvider.notifier).state = newDistance;
    }
  }

  void _showDistanceSelector() {
    final unit = ref.read(distanceUnitProvider);
    final quickDistances = unit == DistanceUnit.kilometers
        ? [3.0, 5.0, 10.0, 21.1, 42.2]
        : [2.0, 3.1, 6.2, 13.1, 26.2];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Select Distance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: quickDistances.map((distance) {
                    String label;
                    if (unit == DistanceUnit.kilometers) {
                      if (distance == 21.1)
                        label = 'Half Marathon';
                      else if (distance == 42.2)
                        label = 'Marathon';
                      else
                        label = '${distance.toStringAsFixed(1)} km';
                    } else {
                      if (distance == 13.1)
                        label = 'Half Marathon';
                      else if (distance == 26.2)
                        label = 'Marathon';
                      else
                        label = '${distance.toStringAsFixed(1)} mi';
                    }

                    return ElevatedButton(
                      onPressed: () {
                        ref.read(tempSelectedDistanceProvider.notifier).state =
                            distance;
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromRGBO(140, 82, 255, 1.0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(label),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCustomDistanceInput();
                  },
                  child: const Text('Enter Custom Distance'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCustomDistanceInput() async {
    final currentDistance = ref.read(tempSelectedDistanceProvider) ?? 5.0;

    final result = await pickDistance(
      context,
      initial: currentDistance,
    );

    if (result != null && result > 0) {
      ref.read(tempSelectedDistanceProvider.notifier).state = result;
    }
  }

  void _showTimeSelector() async {
    final currentTime =
        ref.read(tempSelectedTimeProvider) ?? const Duration(minutes: 30);

    final result = await pickCupertinoDuration(
      context,
      initial: currentTime,
    );

    if (result != null) {
      ref.read(tempSelectedTimeProvider.notifier).state = result;
    }
  }

  String _formatTime(Duration? duration) {
    if (duration == null) return '0s';

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
      if (seconds > 0) {
        return '${minutes}m ${seconds}s';
      } else {
        return '${minutes}m';
      }
    } else {
      return '${seconds}s';
    }
  }
}
