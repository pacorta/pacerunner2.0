import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'current_pace_in_seconds_provider.dart';
import 'distance_unit_provider.dart';

class PaceBar extends ConsumerStatefulWidget {
  const PaceBar({
    super.key,
    this.width = 300.0,
    this.height = 60.0,
    this.minPaceSecondsPerMile = 300.0,
    this.maxPaceSecondsPerMile = 900.0,
    this.targetZoneStart = 0.33,
    this.targetZoneEnd = 0.67,
  });

  final double width;
  final double height;
  final double minPaceSecondsPerMile;
  final double maxPaceSecondsPerMile;
  final double targetZoneStart;
  final double targetZoneEnd;

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
    // Watch both the pace provider and the distance unit provider.
    final paceInSecondsPerMile = ref.watch(currentPaceInSecondsProvider);
    final distanceUnit = ref.watch(distanceUnitProvider);

    // Adjust the pace value if the unit is kilometers.
    double adjustedPace;
    if (distanceUnit == DistanceUnit.kilometers) {
      adjustedPace = _convertPaceToKilometers(paceInSecondsPerMile);
    } else {
      adjustedPace = paceInSecondsPerMile;
    }

    // Calculate normalized pace.
    double normalizedPace;
    if (adjustedPace > 0) {
      normalizedPace = 1 -
          (adjustedPace - widget.minPaceSecondsPerMile) /
              (widget.maxPaceSecondsPerMile - widget.minPaceSecondsPerMile);
      normalizedPace = normalizedPace.clamp(0.0, 1.0);
      lastValidIconPosition = normalizedPace;

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

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Visibility(
            visible: normalizedPace >= widget.targetZoneStart &&
                normalizedPace <= widget.targetZoneEnd,
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
                colors: [
                  Colors.red,
                  Colors.yellow,
                  Colors.green,
                  Colors.yellow,
                  Colors.red
                ],
                stops: [
                  0.0,
                  widget.targetZoneStart,
                  (widget.targetZoneStart + widget.targetZoneEnd) / 2,
                  widget.targetZoneEnd,
                  1.0
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

  // Helper method to convert pace from seconds per mile to seconds per kilometer.
  double _convertPaceToKilometers(double paceInSecondsPerMile) {
    const mileToKilometer = 1.60934;
    return paceInSecondsPerMile / mileToKilometer;
  }
}
