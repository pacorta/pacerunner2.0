import 'package:flutter/material.dart';

class PaceBar extends StatefulWidget {
  const PaceBar({super.key, this.width = 300.0, this.height = 60.0});
  final double width;
  final double height;

  @override
  State<PaceBar> createState() => _PaceBarState();
}

class _PaceBarState extends State<PaceBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize the AnimationController
    _controller = AnimationController(
      duration: const Duration(seconds: 3), // Duration for one-way animation
      vsync: this,
    );

    // Define a Tween to animate the position of the icon
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Start the animation with reverse
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Conditional smiley face
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              // Calculate the position of the icon
              double iconPosition = _animation.value * (300.0 - 50.0);
              bool isInGreenZone =
                  iconPosition >= 100.0 && iconPosition <= 200.0;

              return Visibility(
                visible: isInGreenZone,
                child: const Icon(
                  Icons.sentiment_very_satisfied_rounded,
                  size: 40.0,
                  color: Color.fromARGB(255, 80, 91, 80),
                ),
              );
            },
          ),
          const SizedBox(height: 10.0), // Spacing between smiley face and bar
          // The bar with the animated icon
          Container(
            width: 300.0,
            height: 60.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              color: Colors.red,
            ),
            child: Stack(
              children: [
                // Green area in the middle
                Positioned(
                  left: 100.0,
                  right: 100.0,
                  top: 0.0,
                  bottom: 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.lightGreenAccent,
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
                // Animated Running Icon
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Positioned(
                      left: _animation.value *
                          (300.0 - 50.0), // Adjust to keep icon within the bar
                      top: 5.0,
                      child: child!,
                    );
                  },
                  child: const Icon(
                    Icons.directions_run,
                    size: 50.0,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
