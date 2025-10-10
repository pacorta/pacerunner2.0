import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/run_save_service.dart';
import 'manual_activity_duration_picker.dart';
import 'manual_activity_distance_picker.dart';
import 'manual_activity_pace_picker.dart';
import 'manual_activity_datetime_picker.dart';

class AddManualActivityModal extends ConsumerStatefulWidget {
  const AddManualActivityModal({super.key});

  @override
  ConsumerState<AddManualActivityModal> createState() =>
      _AddManualActivityModalState();
}

class _AddManualActivityModalState
    extends ConsumerState<AddManualActivityModal> {
  // Date/Time
  DateTime _selectedDateTime = DateTime.now();

  // Duration (time)
  Duration? _duration;

  // Distance
  double? _distance;
  String _distanceUnit = 'mi';

  // Pace
  int? _paceSeconds;
  String _paceUnit = 'mi';

  // Simplified tracking using timestamps
  DateTime? _timeLastEdited;
  DateTime? _distanceLastEdited;
  DateTime? _paceLastEdited;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill current date/time
    _selectedDateTime = DateTime.now();
  }

  /// Calculate pace from time and distance
  void _autoCalculatePace() {
    if (_duration == null || _distance == null || _distance! <= 0) return;

    final totalSeconds = _duration!.inSeconds;
    if (totalSeconds <= 0) return;

    final paceInSeconds = totalSeconds / _distance!;
    _paceSeconds = paceInSeconds.round().clamp(0, 3599); // Max 59:59
  }

  /// Calculate distance from time and pace
  void _autoCalculateDistance() {
    if (_duration == null || _paceSeconds == null || _paceSeconds! <= 0) return;

    final totalSeconds = _duration!.inSeconds;
    final calculatedDistance = totalSeconds / _paceSeconds!;
    _distance = calculatedDistance.clamp(0.0, 999.9);
  }

  /// Calculate time from distance and pace
  void _autoCalculateTime() {
    if (_distance == null ||
        _paceSeconds == null ||
        _distance! <= 0 ||
        _paceSeconds! <= 0) return;

    final totalSeconds = (_distance! * _paceSeconds!).round();
    _duration =
        Duration(seconds: totalSeconds.clamp(0, 359999)); // Max 99:59:59
  }

  /// Simplified recalculation logic
  void _recalculate() {
    // Contar campos llenos
    final hasTime = _duration != null && _duration!.inSeconds > 0;
    final hasDistance = _distance != null && _distance! > 0;
    final hasPace = _paceSeconds != null && _paceSeconds! > 0;

    final filledCount = [hasTime, hasDistance, hasPace].where((x) => x).length;

    // Si solo 2 campos llenos, calcular el tercero
    if (filledCount == 2) {
      if (!hasTime) {
        _autoCalculateTime();
      } else if (!hasDistance) {
        _autoCalculateDistance();
      } else if (!hasPace) {
        _autoCalculatePace();
      }
    }
    // Si 3 campos llenos, recalcular el editado menos recientemente
    else if (filledCount == 3) {
      final times = [
        if (_timeLastEdited != null) _timeLastEdited!,
        if (_distanceLastEdited != null) _distanceLastEdited!,
        if (_paceLastEdited != null) _paceLastEdited!,
      ]..sort();

      if (times.length == 3) {
        final oldest = times.first;
        if (oldest == _timeLastEdited) {
          _autoCalculateTime();
        } else if (oldest == _distanceLastEdited) {
          _autoCalculateDistance();
        } else {
          _autoCalculatePace();
        }
      }
    }
  }

  /// Synchronize distance and pace units (CRITICAL: no value conversion)
  void _syncUnits(String newUnit) {
    setState(() {
      _distanceUnit = newUnit;
      _paceUnit = newUnit;
    });
  }

  /// Format duration as HH:MM:SS
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format pace as MM:SS
  String _formatPace(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Format date: "Today at 3:56 PM" or "Tue Oct 7"
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();

    // Check if it's today
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return 'Today at ${DateFormat('h:mm a').format(dateTime)}';
    }

    // Format as "Tue Oct 7"
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final dayName = dayNames[dateTime.weekday - 1];
    final monthName = monthNames[dateTime.month - 1];
    final time = DateFormat('h:mm a').format(dateTime);

    return '$dayName $monthName ${dateTime.day} at $time';
  }

  /// Pick date and time using native iOS picker
  Future<void> _pickDateTime() async {
    final result = await pickManualActivityDateTime(
      context,
      initial: _selectedDateTime,
    );

    if (result != null && mounted) {
      setState(() {
        _selectedDateTime = result;
      });
    }
  }

  /// Pick duration
  Future<void> _pickDuration() async {
    final result = await pickManualActivityDuration(
      context,
      initial: _duration ?? Duration.zero,
    );

    if (result != null && mounted) {
      setState(() {
        _duration = result;
        _timeLastEdited = DateTime.now();
        _recalculate();
      });
    }
  }

  /// Pick distance
  Future<void> _pickDistance() async {
    final result = await pickManualActivityDistance(
      context,
      initialValue: _distance ?? 0.0,
      initialUnit: _distanceUnit,
    );

    if (result != null && mounted) {
      setState(() {
        _distance = result['value'];
        final newUnit = result['unit'];
        _distanceLastEdited = DateTime.now();

        // Sync units if changed
        if (newUnit != _distanceUnit) {
          _syncUnits(newUnit);
        } else {
          _recalculate();
        }
      });
    }
  }

  /// Pick pace
  Future<void> _pickPace() async {
    final result = await pickManualActivityPace(
      context,
      initialSeconds: _paceSeconds ?? 0,
      initialUnit: _paceUnit,
    );

    if (result != null && mounted) {
      setState(() {
        _paceSeconds = result['seconds'];
        final newUnit = result['unit'];
        _paceLastEdited = DateTime.now();

        // Sync units if changed
        if (newUnit != _paceUnit) {
          _syncUnits(newUnit);
        } else {
          _recalculate();
        }
      });
    }
  }

  /// Validate all fields are filled
  bool _validateFields() {
    return _duration != null &&
        _duration!.inSeconds > 0 &&
        _distance != null &&
        _distance! > 0 &&
        _paceSeconds != null &&
        _paceSeconds! > 0;
  }

  /// Save activity
  Future<void> _saveActivity() async {
    // Don't allow saving if fields are incomplete
    if (!_validateFields()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Build run data
      final runData = {
        'distance': _distance!,
        'distanceUnitString': _distanceUnit,
        'time': _formatDuration(_duration!),
        'averagePace': '${_formatPace(_paceSeconds!)}/$_paceUnit',
        'startTime': _selectedDateTime.toIso8601String(),
        'date': _selectedDateTime.toString().split(' ')[0],
        'timestamp':
            _selectedDateTime, // Will be converted to FieldValue.serverTimestamp in service
        'isManual': true, // CRITICAL: Mark as manual activity
        'goalAchieved': false,
        'totalRunTimeSeconds': _duration!.inSeconds,
      };

      // Save to Firestore
      await RunSaveService.saveManualRun(runData);

      if (mounted) {
        // Success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Close modal and return to Activities
        Navigator.of(context).pop(true); // true indicates success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving activity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.63,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Add Manual Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
            ),

            // Form fields
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Date/Time field
                    _buildFieldRow(
                      icon: Icons.calendar_today_outlined,
                      value: _formatDateTime(_selectedDateTime),
                      onTap: _pickDateTime,
                    ),
                    const SizedBox(height: 12),

                    // Duration field
                    _buildFieldRow(
                      icon: Icons.access_time_outlined,
                      value: _duration != null
                          ? _formatDuration(_duration!)
                          : '00:00:00',
                      onTap: _pickDuration,
                      valueColor:
                          _duration != null ? Colors.black : Colors.grey,
                    ),
                    const SizedBox(height: 12),

                    // Distance field
                    _buildFieldRow(
                      icon: Icons.location_on_outlined,
                      value: _distance != null
                          ? '${_distance!.toStringAsFixed(1)} $_distanceUnit'
                          : '0.00 mi',
                      onTap: _pickDistance,
                      valueColor:
                          _distance != null ? Colors.black : Colors.grey,
                    ),
                    const SizedBox(height: 12),

                    // Pace field (auto-calculated)
                    _buildFieldRow(
                      icon: Icons.speed_outlined,
                      value: _paceSeconds != null
                          ? '${_formatPace(_paceSeconds!)}/$_paceUnit'
                          : '0:00 /mi',
                      onTap: _pickPace,
                      valueColor:
                          _paceSeconds != null ? Colors.black : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            // Save button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : (_validateFields() ? _saveActivity : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _validateFields()
                        ? const Color.fromRGBO(
                            140, 82, 255, 1.0) // Purple when complete
                        : Colors.grey.shade400, // Gray when incomplete
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Activity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow({
    required IconData icon,
    required String value,
    required VoidCallback onTap,
    Color valueColor = Colors.black,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon on the left
            Icon(
              icon,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 12),

            // Value in the center (expanded)
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor,
                ),
              ),
            ),

            // Chevron on the right
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

/// Show the Add Manual Activity modal
Future<bool?> showAddManualActivityModal(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AddManualActivityModal(),
  );
}
