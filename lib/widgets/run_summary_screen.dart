import 'package:flutter/material.dart';

import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'run_summary_card.dart';
import '../firebase/firebaseWidgets/running_stats.dart';
// Removed direct Firebase imports; saving now happens at FINISH
import 'distance_provider.dart';
import 'speed_provider.dart';
import 'elapsed_time_provider.dart';
import 'current_pace_provider.dart';
import 'stable_average_pace_provider.dart';
import 'projected_finish_provider.dart';
import 'current_pace_in_seconds_provider.dart';
import 'inline_goal_input.dart';
import 'goal_progress_provider.dart';
import 'distance_unit_provider.dart';
import 'target_providers.dart';
import 'time_goal_provider.dart';
import 'run_state_provider.dart';
import '../services/live_activity_service.dart';
import '../services/run_save_service.dart';

class RunSummaryScreen extends ConsumerStatefulWidget {
  final Uint8List? mapSnapshot;
  final double distance;
  final String distanceUnitString;
  final String finalTime;
  final String finalPace;
  final DateTime? runStartTime;
  final String? savedRunDocId;

  const RunSummaryScreen({
    super.key,
    this.mapSnapshot,
    required this.distance,
    required this.distanceUnitString,
    required this.finalTime,
    required this.finalPace,
    this.runStartTime,
    this.savedRunDocId,
  });

  @override
  ConsumerState<RunSummaryScreen> createState() => _RunSummaryScreenState();
}

class _RunSummaryScreenState extends ConsumerState<RunSummaryScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final ValueNotifier<bool> _exportWithoutBackground = ValueNotifier(false);
  late ConfettiController _confettiController;
  bool _confettiPlayed = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _exportWithoutBackground.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // Copy run summary to clipboard as PNG
  Future<void> _copyToClipboard() async {
    try {
      // Render once without the card background so the exported image
      // can be pasted over photos (Instagram stories, etc.).
      _exportWithoutBackground.value = true;
      // Wait one frame so the widget rebuilds without background
      await Future.delayed(const Duration(milliseconds: 16));

      // Get the RepaintBoundary
      final RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // Capture as image with high quality
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // Convert to PNG bytes
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Copy PNG bytes to system clipboard (not base64 text)
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        throw Exception('Clipboard not available on this platform');
      }
      final item = DataWriterItem();
      item.add(Formats.png(pngBytes));
      await clipboard.write([item]);

      // Restore background for on-screen display
      if (mounted) {
        _exportWithoutBackground.value = false;
      }

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied. Paste in your story :)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error copying to clipboard: $e');
      if (mounted) {
        _exportWithoutBackground.value = false;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _triggerConfetti() {
    _confettiController.play();
  }

  void _saveRun() async {
    await LiveActivityService.endRunningActivity();

    // Reset Providers (data was already saved on FINISH)
    ref.read(distanceProvider.notifier).state = 0.0;
    ref.read(speedProvider.notifier).state = 0.0;
    ref.read(elapsedTimeProvider.notifier).state = '00:00:00';
    resetCurrentPaceInSecondsProvider();
    resetCurrentPaceProvider();
    resetStableAveragePace(ref);
    resetPredictionProviders(ref);

    // Clear goal-progress tracking
    clearGoalProgressProviders(ref);

    // Clear goal so Home shows blank after finishing
    clearGoalProviders(ref);

    // Reset run state so next session starts fresh
    ref.read(runStateProvider.notifier).state = RunState.fetchingGPS;

    // Navigate to Running Stats Page with NO transitions
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RunningStatsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child; // No transition, just show the page
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _showDiscardConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red.shade600, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Discard Run',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to discard this run?',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF34495E),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone. Your run data will be lost forever.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
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
            child: Text(
              'Keep Run',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _discardRun();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Discard Run',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _discardRun() async {
    // Delete the saved run from database if we have the docId
    if (widget.savedRunDocId != null) {
      try {
        await RunSaveService.deleteRun(widget.savedRunDocId!);
        // ignore: avoid_print
        print('RunSummary: deleted saved run ${widget.savedRunDocId}');
      } catch (e) {
        // ignore: avoid_print
        print('RunSummary: error deleting run: $e');
      }
    }

    await LiveActivityService.endRunningActivity();
    // Reset Providers
    ref.read(distanceProvider.notifier).state = 0.0;
    ref.read(speedProvider.notifier).state = 0.0;
    ref.read(elapsedTimeProvider.notifier).state = '00:00:00';
    resetCurrentPaceInSecondsProvider();
    resetCurrentPaceProvider();
    resetStableAveragePace(ref);
    resetPredictionProviders(ref);

    // Clear goal-progress tracking
    clearGoalProgressProviders(ref);

    // Clear goal so Home shows blank when discarding
    clearGoalProviders(ref);

    // Reset run state so next session starts fresh
    ref.read(runStateProvider.notifier).state = RunState.fetchingGPS;

    // Navigate back to root (RootShell) to restore bottom nav
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // Determine goal outcome
    final hasDistanceTimeGoal =
        ref.watch(hadDistanceTimeGoalProvider); // distance+time goal
    final hasDistanceOnlyGoal = ref.watch(hadDistanceOnlyGoalProvider);
    final hasTimeOnlyGoal = ref.watch(hadTimeOnlyGoalProvider);
    // First reach time string available if needed in future
    // final firstReachTimeStr = ref.watch(firstReachTargetTimeStringProvider);
    final firstReachTimeSecs = ref.watch(firstReachTargetTimeSecondsProvider);
    final targetTimeSecs = ref.watch(targetTimeProvider);
    final targetDistance = ref.watch(targetDistanceProvider);
    final unit = ref.watch(distanceUnitProvider);

    // Compute goal met and header texts
    bool goalMet = false;
    String headerTitle = 'Nice run!';
    String headerSubtitle = '';

    if (hasDistanceTimeGoal &&
        targetDistance != null &&
        targetTimeSecs != null) {
      // Apply same epsilon tolerance and fallback as in _saveRun()
      final double eps =
          unit == DistanceUnit.kilometers ? 0.02 : 0.01; // km or miles
      final bool reachedByDistance = widget.distance + eps >= targetDistance;

      double? reachTimeSecs = firstReachTimeSecs;
      if (reachTimeSecs == null && reachedByDistance) {
        // Fallback to total elapsed from finalTime string
        final parts = widget.finalTime.split(':');
        if (parts.length == 3) {
          reachTimeSecs = (int.parse(parts[0]) * 3600 +
                  int.parse(parts[1]) * 60 +
                  int.parse(parts[2]))
              .toDouble();
        }
      }

      goalMet = reachTimeSecs != null && reachTimeSecs <= targetTimeSecs;

      if (goalMet) {
        headerTitle = 'You met your goal!';
        // Show the goal text like "5km under 30m"
        final unitLabel = unit == DistanceUnit.kilometers ? 'km' : 'mi';
        // Format target time
        String targetTimeLabel;
        final hours = (targetTimeSecs / 3600).floor();
        final minutes = ((targetTimeSecs % 3600) / 60).floor();
        final seconds = (targetTimeSecs % 60).floor();
        if (hours > 0) {
          targetTimeLabel = '${hours}h ${minutes}m';
        } else if (minutes > 0) {
          targetTimeLabel = seconds > 0 && minutes < 5
              ? '${minutes}m ${seconds}s'
              : '${minutes}m';
        } else {
          targetTimeLabel = '${seconds}s';
        }
        headerSubtitle =
            '${targetDistance.toStringAsFixed(1)} $unitLabel under $targetTimeLabel';
      } else {
        headerTitle = 'Maybe next time 😅';

        if (firstReachTimeSecs == null &&
            !(widget.distance +
                    (unit == DistanceUnit.kilometers ? 0.02 : 0.01) >=
                targetDistance)) {
          // Truly short on distance
          final unitLabel = unit == DistanceUnit.kilometers ? 'km' : 'mi';
          final remaining =
              (targetDistance - widget.distance).clamp(0, double.infinity);
          final remainingText = remaining >= 1.0
              ? remaining.toStringAsFixed(1)
              : remaining.toStringAsFixed(2);
          headerSubtitle = 'You were short by $remainingText $unitLabel';
        } else {
          // User reached distance but after target time → show time off
          final diff = ((firstReachTimeSecs ?? 0) - targetTimeSecs)
              .clamp(0, double.infinity);
          final dm = (diff / 60).floor();
          final ds = (diff % 60).floor();
          final offText = dm > 0 ? '${dm}m ${ds}s' : '${ds}s';
          headerSubtitle = 'You were off your goal by $offText';
        }
      }
    } else if (hasDistanceOnlyGoal && targetDistance != null) {
      // Distance-only goal evaluation (apply epsilon tolerance)
      final unitLabel = unit == DistanceUnit.kilometers ? 'km' : 'mi';
      final double eps = unit == DistanceUnit.kilometers ? 0.02 : 0.01;
      final bool reachedByDistance = widget.distance + eps >= targetDistance;

      if (reachedByDistance) {
        headerTitle = 'You met your goal!';
        headerSubtitle = '${targetDistance.toStringAsFixed(1)} $unitLabel';
      } else {
        headerTitle = 'Maybe next time 😅';
        double remaining =
            (targetDistance - widget.distance).clamp(0, double.infinity);
        // If remaining is within epsilon, show 0.00 to avoid confusing 0.00 shorts
        if (remaining < eps) remaining = 0.0;
        final remainingText = remaining >= 1.0
            ? remaining.toStringAsFixed(1)
            : remaining.toStringAsFixed(2);
        headerSubtitle = 'You were short by $remainingText $unitLabel';
      }
    } else if (hasTimeOnlyGoal) {
      // Time-only goal evaluation
      final targetSeconds = ref.watch(timeOnlyGoalSecondsProvider);
      if (targetSeconds != null) {
        double actualSeconds;
        final parts = widget.finalTime.split(':');
        if (parts.length == 3) {
          actualSeconds = (int.parse(parts[0]) * 3600 +
                  int.parse(parts[1]) * 60 +
                  int.parse(parts[2]))
              .toDouble();
        } else {
          actualSeconds = targetSeconds + 1;
        }
        if (actualSeconds >= targetSeconds) {
          headerTitle = 'You met your goal!';
          // Render the target time nicely
          final hours = (targetSeconds / 3600).floor();
          final minutes = ((targetSeconds % 3600) / 60).floor();
          final seconds = (targetSeconds % 60).floor();
          String targetLabel = hours > 0
              ? '${hours}h ${minutes}m'
              : (minutes > 0
                  ? (seconds > 0 && minutes < 5
                      ? '${minutes}m ${seconds}s'
                      : '${minutes}m')
                  : '${seconds}s');
          headerSubtitle = targetLabel;
        } else {
          headerTitle = 'Maybe next time 😅';
          final diff =
              (targetSeconds - actualSeconds).clamp(0, double.infinity);
          final dm = (diff / 60).floor();
          final ds = (diff % 60).floor();
          final offText = dm > 0 ? '${dm}m ${ds}s' : '${ds}s';
          headerSubtitle = 'You were short by $offText';
        }
      }
    }

    // Trigger confetti automatically if goal was met (any goal type)
    bool celebrate = false;

    if (hasDistanceTimeGoal &&
        targetDistance != null &&
        targetTimeSecs != null) {
      celebrate = goalMet;
    } else if (hasDistanceOnlyGoal && targetDistance != null) {
      celebrate = widget.distance >= targetDistance;
    } else if (hasTimeOnlyGoal) {
      final targetSeconds = ref.watch(timeOnlyGoalSecondsProvider);
      if (targetSeconds != null) {
        final parts = widget.finalTime.split(':');
        double actualSeconds = 0;
        if (parts.length == 3) {
          actualSeconds = (int.parse(parts[0]) * 3600 +
                  int.parse(parts[1]) * 60 +
                  int.parse(parts[2]))
              .toDouble();
        }
        celebrate = actualSeconds >= targetSeconds;
      }
    }

    if (celebrate && !_confettiPlayed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_confettiPlayed) {
          _confettiPlayed = true;
          _confettiController.play();
        }
      });
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color.fromARGB(255, 17, 17, 17),
          body: SafeArea(
            child: Column(
              children: [
                // Header with back button and confetti button
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    headerTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (headerSubtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      headerSubtitle,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // RepaintBoundary wraps the card for future PNG export
                        ValueListenableBuilder<bool>(
                          valueListenable: _exportWithoutBackground,
                          builder: (context, hideBackground, _) {
                            return RepaintBoundary(
                              key: _repaintBoundaryKey,
                              child: RunSummaryCard(
                                mapSnapshot: widget.mapSnapshot,
                                distance: widget.distance.toStringAsFixed(2),
                                pace: widget.finalPace,
                                time: widget.finalTime,
                                distanceUnit: widget.distanceUnitString,
                                showCardBackground: !hideBackground,
                              ),
                            );
                          },
                        ),

                        // Action buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              // Done button

                              const SizedBox(height: 16),

                              // Copy to clipboard button
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: IconButton(
                                  onPressed: _copyToClipboard,
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withOpacity(0.1),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                    shape: const CircleBorder(),
                                  ),
                                  icon: const Icon(
                                    Icons.copy,
                                    size: 20,
                                  ),
                                ),
                              ),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saveRun,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 11),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: const Text(
                                    'Done',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Discard run button
                              TextButton(
                                onPressed: _showDiscardConfirmation,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 12),
                                ),
                                child: const Text(
                                  'Discard run',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Confetti widget positioned at top center
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.purple,
              Colors.white,
              Colors.red,
            ],
            numberOfParticles: 20,
          ),
        ),
        // Confetti button positioned absolutely in top right
        Positioned(
          top: 80, // Position below the header area
          right: 16,
          child: IconButton(
            onPressed: _triggerConfetti,
            style: IconButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.2),
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.all(8),
              shape: const CircleBorder(),
            ),
            icon: const Text(
              '🎉',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ],
    );
  }
}
