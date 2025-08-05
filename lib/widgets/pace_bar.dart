import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/widgets/custom_distance_provider.dart';
import 'package:untitled/widgets/custom_pace_provider.dart';
import 'current_pace_in_seconds_provider.dart';
import 'distance_unit_provider.dart';
import 'run_state_provider.dart';
import 'dart:math';

import 'package:flutter/services.dart';

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
    final currentPaceInSeconds = ref.watch(
        currentPaceInSecondsProvider); //live current pace of the user (which already takes the unit into account)

    // Ensure the necessary values are set
    if (targetPaceSecondsPerMile == null || targetDistanceInMiles == null) {
      return const Center(
        child: Text("Please set your target pace and distance!"),
      );
    }

    // Adjust the pace value if the unit is kilometers
    //This ensures that the PaceBar reflects the correct pace, regardless of whether the user is working with miles or kilometers.
    double convertPace(double pace, DistanceUnit from, DistanceUnit to) {
      if (from == to) return pace;
      const mileToKilometer = 1.60934;
      return from == DistanceUnit.miles
          ? pace * mileToKilometer // Convert to km
          : pace / mileToKilometer; // Convert to miles
    }

    final adjustedPace =
        convertPace(currentPaceInSeconds, DistanceUnit.miles, distanceUnit);

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
      normalizedPace = 1 -
          (adjustedPace - minPaceSecondsPerMile) /
              (maxPaceSecondsPerMile - minPaceSecondsPerMile);
      normalizedPace = normalizedPace.clamp(0.0, 1.0);
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
                // Runner Icon Animation
                AnimatedBuilder(
                  animation: _iconPositionAnimation,
                  builder: (context, child) {
                    return Positioned(
                      left: _iconPositionAnimation.value,
                      top: 5.0,
                      child: _buildRunnerIcon(
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

  // Helper to convert pace from miles to kilometers
  double _convertPaceToKilometers(double paceInSecondsPerMile) {
    const mileToKilometer = 1.60934;
    return paceInSecondsPerMile / mileToKilometer;
  }

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

  Widget _buildRunnerIcon(double pace, double targetStart, double targetEnd) {
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
}
