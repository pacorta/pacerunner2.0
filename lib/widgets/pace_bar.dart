import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/widgets/custom_distance_provider.dart';
import 'package:untitled/widgets/custom_pace_provider.dart';
import 'stable_average_pace_provider.dart';
import 'distance_unit_provider.dart';
import 'run_state_provider.dart';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:untitled/utils/pace_utils.dart';

class PaceBar extends ConsumerStatefulWidget {
  const PaceBar({
    super.key,
    //required this.targetPaceSecondsPerMile, // Target pace (e.g., 480 for 8:00/mile) --removed to let the provider take care of this.
    //required this.distanceInMiles, //Distance of the run
    //this.acceptablePaceVariance = 0.2,        // ±20% from target is considered "good" (green zone)
    //this.totalPaceRange = 0.5,                // ±50% from target is total displayed range
    this.width = 300.0,
    this.height = 60.0,
  });

  //final double targetPaceSecondsPerMile;  //--Removed to let the provider take care of this.
  //final double acceptablePaceVariance;    // As decimal (0.2 = 20%)
  //final double totalPaceRange;            // As decimal (0.5 = 50%)
  //final double distanceInMiles;
  final double width;
  final double height;

  @override
  ConsumerState<PaceBar> createState() => _PaceBarState();
}

class _PaceBarState extends ConsumerState<PaceBar>
    with SingleTickerProviderStateMixin {
  double lastValidIconPosition = 0.5; // Default to center
  late AnimationController _animationController;
  late Animation<double> _iconPositionAnimation;
  bool _wasInTargetZone = false;

  // Normaliza de forma segura evitando divisiones por cero y valores no finitos
  double _safeNormalize(
    double value,
    double min,
    double max,
    double fallback,
  ) {
    final denom = max - min;
    if (!denom.isFinite || denom.abs() < 1e-6) {
      return fallback.clamp(0.0, 1.0);
    }

    // 1 - ((value - min) / (max - min)) para que menor tiempo = más rápido = derecha
    final normalized = 1 - ((value - min) / denom);
    if (!normalized.isFinite) {
      return fallback.clamp(0.0, 1.0);
    }
    return normalized.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconPositionAnimation = Tween<double>(begin: 0.5, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch all relevant providers
    final targetPaceSecondsPerMile =
        ref.watch(customPaceProvider); //Target pace goal set by the user
    final targetDistanceInMiles = ref
        .watch(customDistanceProvider); //Target distance goal set by the user
    final distanceUnit =
        ref.watch(distanceUnitProvider); //unit selected by the user
    final stablePaceString = ref.watch(stableAveragePaceProvider);
    final currentPaceInSeconds = parsePaceStringToSeconds(
        stablePaceString); //stable average pace converted to seconds

    print('PaceBar DEBUG:');
    print('  Stable pace string: $stablePaceString');
    print('  Parsed to seconds: $currentPaceInSeconds');
    print('  Target pace: $targetPaceSecondsPerMile sec/unit');
    print('  Distance unit: $distanceUnit');
    print('  Target distance: $targetDistanceInMiles');

    // Ensure the necessary values are set
    if (targetPaceSecondsPerMile == null || targetDistanceInMiles == null) {
      return const Center(
        child: Text("Please set your target pace and distance!"),
      );
    }

    // Use pace as-is; it already matches the selected unit (km or mi)
    final adjustedPace = currentPaceInSeconds;

    // Calculate variance and range based on distance
    double acceptablePaceVariance =
        _calculateVariance(targetDistanceInMiles, distanceUnit);
    double totalPaceRange = _calculateTotalRange(targetDistanceInMiles);

    // Calculate good pace ranges using adaptive variance
    double minGoodPace =
        targetPaceSecondsPerMile * (1 - acceptablePaceVariance);
    double maxGoodPace =
        targetPaceSecondsPerMile * (1 + acceptablePaceVariance);

    // Calculate total range of paces
    double minPaceSecondsPerMile =
        targetPaceSecondsPerMile * (1 - totalPaceRange);
    double maxPaceSecondsPerMile =
        targetPaceSecondsPerMile * (1 + totalPaceRange);

    // Calculate bar positions for the good pace zone
    double targetZoneStart = (maxPaceSecondsPerMile - maxGoodPace) /
        (maxPaceSecondsPerMile - minPaceSecondsPerMile);
    double targetZoneEnd = (maxPaceSecondsPerMile - minGoodPace) /
        (maxPaceSecondsPerMile - minPaceSecondsPerMile);

    // Calculate the normalized position (0.0 to 1.0) on the bar
    double normalizedPace;
    if (adjustedPace > 0) {
      // Normalizacion segura para evitar NaN/Inf o division por cero
      normalizedPace = _safeNormalize(
        adjustedPace,
        minPaceSecondsPerMile,
        maxPaceSecondsPerMile,
        lastValidIconPosition,
      );
      lastValidIconPosition = normalizedPace;

      // To trigger haptic feedback
      _updatePaceStatus(normalizedPace, targetZoneStart, targetZoneEnd);

      _iconPositionAnimation = Tween<double>(
        begin: _iconPositionAnimation.value,
        end: normalizedPace * (widget.width - 50.0),
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );
      _animationController.forward(from: 0);
    } else {
      normalizedPace = lastValidIconPosition;
    }

    // Build the UI
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pace Status Icon & Message - COMMENTED OUT
          // _buildPaceStatusIndicator(
          //     normalizedPace, targetZoneStart, targetZoneEnd),
          // const SizedBox(height: 10.0),
          // Pace Bar
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              gradient: LinearGradient(
                colors: const [
                  Colors.red,
                  Colors.yellow,
                  Colors.green,
                  Colors.yellow,
                  Colors.red
                ],
                stops: [
                  0.0,
                  targetZoneStart,
                  (targetZoneStart + targetZoneEnd) / 2,
                  targetZoneEnd,
                  1.0
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8.0,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2.0,
              ),
            ),
            child: Stack(
              children: [
                // Time markers inside the bar
                /*_buildTimeMarkers(
                  targetPaceSecondsPerMile,
                  targetDistanceInMiles,
                  distanceUnit,
                  minPaceSecondsPerMile,
                  maxPaceSecondsPerMile,
                ),*/

                // Icon Animation
                AnimatedBuilder(
                  animation: _iconPositionAnimation,
                  builder: (context, child) {
                    return Positioned(
                      left: _iconPositionAnimation.value,
                      top: 5.0,
                      child: _buildIcon(
                          normalizedPace, targetZoneStart, targetZoneEnd),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10.0),
          // Motivational Message
          /*_buildMotivationalMessage(
              normalizedPace, targetZoneStart, targetZoneEnd),*/
        ],
      ),
    );
  }

  // Helper to calculate variance based on distance
  double _calculateVariance(double distance, DistanceUnit unit) {
    double targetDistanceInMiles =
        unit == DistanceUnit.kilometers ? distance / 1.60934 : distance;
    double baseVariance = 0.20;
    return (baseVariance * exp(-0.05 * (targetDistanceInMiles - 1)))
        .clamp(0.05, 0.20);
  }

  // Helper to calculate total range based on distance
  double _calculateTotalRange(double targetDistanceInMiles) {
    double baseRange = 0.50;
    double adaptiveRange = baseRange * exp(-0.03 * (targetDistanceInMiles - 1));
    return adaptiveRange.clamp(0.15, 0.50);
  }
  /*
  Widget _buildPaceStatusIndicator(
      double pace, double targetStart, double targetEnd) {
    if (pace >= targetStart && pace <= targetEnd) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sentiment_very_satisfied_rounded,
            size: 40.0,
            color: Colors.green,
          ),
          const SizedBox(width: 8.0),
          const Text(
            "Perfect Pace!",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
  */

  Widget _buildIcon(double pace, double targetStart, double targetEnd) {
    double iconSize = 50.0;

    if (pace >= targetStart && pace <= targetEnd) {
      iconSize = 55.0; // Slightly larger when in perfect zone
    }

    // Check if the run is paused
    final runState = ref.watch(runStateProvider);
    final isPaused = runState == RunState.paused;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Image.asset(
        isPaused ? 'images/bud-pause.gif' : 'images/bud.gif',
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildMotivationalMessage(
      double pace, double targetStart, double targetEnd) {
    String message;
    Color messageColor;
    IconData messageIcon;

    if (pace < targetStart) {
      if (pace < targetStart * 0.5) {
        message = "Speed up";
        messageIcon = Icons.directions_run;
      } else {
        message = "A little faster";
        messageIcon = Icons.trending_up;
      }
      messageColor = const Color.fromARGB(255, 0, 0, 0);
    } else if (pace > targetEnd) {
      if (pace > targetEnd * 1.5) {
        message = "Slow down a little";
        messageIcon = Icons.warning;
      } else {
        message = "Relax";
        messageIcon = Icons.trending_down;
      }
      messageColor = const Color.fromARGB(255, 0, 0, 0);
    } else {
      message = "Perfect pace";
      messageIcon = Icons.stars;
      messageColor = const Color.fromARGB(255, 0, 0, 0);
    }
    //I'm just going to use the display messages during production, later on they'll be haptic feedback or sound effects.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(messageIcon, color: messageColor),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Text(
            message,
            key: ValueKey(message),
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: messageColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  void _updatePaceStatus(
      double normalizedPace, double targetZoneStart, double targetZoneEnd) {
    bool isInTargetZone =
        normalizedPace >= targetZoneStart && normalizedPace <= targetZoneEnd;
    //haptic feedback (medium impact when in target zone, light impact when not)
    if (isInTargetZone != _wasInTargetZone) {
      if (isInTargetZone) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      _wasInTargetZone = isInTargetZone;
    }
  }
/*
  // Build time markers inside the pace bar
  Widget _buildTimeMarkers(
    double? targetPaceSecondsPerMile,
    double? targetDistanceInMiles,
    DistanceUnit distanceUnit,
    double minPaceSecondsPerMile,
    double maxPaceSecondsPerMile,
  ) {
    if (targetPaceSecondsPerMile == null || targetDistanceInMiles == null) {
      return const SizedBox.shrink();
    }

    // Use distance in the same unit as pace (selected unit)
    final distanceInSelectedUnit = targetDistanceInMiles;

    // Calculate projected finish times for different positions
    final slowTime =
        _formatProjectedTime(maxPaceSecondsPerMile * distanceInSelectedUnit);
    final targetTime =
        _formatProjectedTime(targetPaceSecondsPerMile * distanceInSelectedUnit);
    final fastTime =
        _formatProjectedTime(minPaceSecondsPerMile * distanceInSelectedUnit);
    return Stack(
      children: [
        // Slow marker (left side)
        Positioned(
          left: 8,
          top: widget.height * 0.3,
          child: _buildTimeMarker(slowTime, true),
        ),

        // Target marker (center)
        Positioned(
          left: (widget.width - 40) / 2,
          top: widget.height * 0.3,
          child: _buildTimeMarker(targetTime, false),
        ),

        // Fast marker (right side)
        Positioned(
          right: 8,
          top: widget.height * 0.3,
          child: _buildTimeMarker(fastTime, true),
        ),
      ],
    );
  }
*/

  /*
  Widget _buildTimeMarker(String time, bool isSideMarker) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        time,
        style: TextStyle(
          fontSize: isSideMarker ? 8 : 9,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  

  // Format projected time as HH:MM or MM:SS
  String _formatProjectedTime(double totalSeconds) {
    final hours = (totalSeconds / 3600).floor();
    final minutes = ((totalSeconds % 3600) / 60).floor();
    final seconds = (totalSeconds % 60).round();

    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}m';
    } else {
      return '${minutes}m${seconds.toString().padLeft(2, '0')}s';
    }
  }
  */
}
