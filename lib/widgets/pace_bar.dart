import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/widgets/custom_distance_provider.dart';
import 'package:untitled/widgets/custom_pace_provider.dart';
import 'current_pace_in_seconds_provider.dart';
import 'distance_unit_provider.dart';
import 'dart:math';

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

      // Animate the runner icon to the new position
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
          Visibility(
            visible: normalizedPace >= targetZoneStart &&
                normalizedPace <= targetZoneEnd,
            child: const Icon(
              Icons.sentiment_very_satisfied_rounded,
              size: 40.0,
              color: Color.fromARGB(255, 80, 91, 80),
            ),
          ),
          const SizedBox(height: 10.0),
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              gradient: LinearGradient(
                colors: const [
                  Colors.red, // Too slow
                  Colors.yellow, // Getting there
                  Colors.green, // Just right
                  Colors.yellow, // Getting too fast
                  Colors.red // Too fast
                ],
                stops: [
                  0.0,
                  targetZoneStart,
                  (targetZoneStart + targetZoneEnd) / 2,
                  targetZoneEnd,
                  1.0,
                ],
              ),
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _iconPositionAnimation,
                  builder: (context, child) {
                    return Positioned(
                      left: _iconPositionAnimation.value,
                      top: 5.0,
                      child: const Icon(
                        Icons.directions_run,
                        size: 50.0,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
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
}
