//PACE SELECTION: This widget allows the user to select a distance and a time for their run.
//Update on 12/03/2024 does the following:
//- Added a "Custom" button to allow the user to enter a custom distance.
//- Added a "Confirm Distance" button to confirm the distance selection.
//- Added a "Confirm Time" button to confirm the time selection.
//- Added a "Start Running" button to start the run with the selected distance and time.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'custom_pace_provider.dart';
import 'custom_distance_provider.dart';
import 'distance_unit_provider.dart';

import 'tracking_provider.dart';
import 'distance_provider.dart';

import 'current_run.dart';

/*
import 'package:untitled/widgets/distance_unit_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/widgets/pace_selection.dart';
*/

class PaceSelectionWidget extends ConsumerStatefulWidget {
  //final Function(double, double)? onConfirmPace; // Collects distance and pace.

  //final Function(double)?
  //onConfirmDistance; //Collects distance for pacebar variance.

  const PaceSelectionWidget({
    Key? key,
    //this.onConfirmPace,
    //this.onConfirmDistance,
  }) : super(key: key);

  @override
  ConsumerState<PaceSelectionWidget> createState() =>
      _PaceSelectionWidgetState();
}

class _PaceSelectionWidgetState extends ConsumerState<PaceSelectionWidget> {
  final TextEditingController _distanceController = TextEditingController();
  double? selectedDistance;
  double selectedTime = 0; // Time from the slider in minutes
  double minTime = 0;
  double maxTime = 0;

  bool isDistanceConfirmed = false;
  bool isTimeConfirmed = false;

  @override
  void initState() {
    super.initState();
    // GPS se manejará en CurrentRun screen
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  // Builds a responsive UI with a three-step wizard pattern:
  // 1. Distance Selection
  // 2. Time Selection
  // 3. Final Confirmation
  // Uses conditional rendering based on user progress.

  @override
  Widget build(BuildContext context) {
    final distanceUnit = ref.watch(distanceUnitProvider);
    final isTracking = ref.watch(trackingProvider);
    final unitLabel = distanceUnit == DistanceUnit.kilometers ? 'km' : 'mi';
    final distances = distanceUnit == DistanceUnit.kilometers
        ? [/*1.0,*/ 5.0, 10.0, 21.1, 42.2]
        : [/*1.0,*/ 3.1, 6.2, 13.1, 26.2];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Plan Your Run',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 211, 118, 72),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 230, 61, 42),
              Color.fromARGB(255, 211, 118, 72),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isDistanceConfirmed) ...[
                    _buildStepIndicator('STEP 1', 'Select Distance'),
                    const SizedBox(height: 20),
                    _buildSelectedGoalCards(),
                    const SizedBox(height: 20),
                    _buildButtonWrap(distances.map((d) {
                      final label = d == 42.2 || d == 26.2
                          ? 'Marathon'
                          : '${d.toStringAsFixed(1)} $unitLabel';
                      return _buildQuickButton(label, d);
                    }).toList()
                      ..add(_buildCustomButton(
                        "Custom",
                        _distanceController,
                        "Enter distance in $unitLabel",
                        (value) =>
                            _handleDistanceSelection(double.parse(value)),
                      ))),
                    const SizedBox(height: 20),
                    _buildConfirmDistanceButton(),
                  ],
                  if (isDistanceConfirmed && !isTimeConfirmed) ...[
                    _buildStepIndicator('STEP 2', 'Select Time'),
                    const SizedBox(height: 20),
                    _buildSelectedGoalCards(),
                    const SizedBox(height: 20),
                    _buildTimeSlider(),
                    const SizedBox(height: 20),
                    _buildConfirmPaceButton(),
                  ],
                  if (isDistanceConfirmed && isTimeConfirmed) ...[
                    _buildStepIndicator('STEP 3', 'Confirm Your Goals'),
                    const SizedBox(height: 20),
                    _buildSelectedGoalCards(),
                    const SizedBox(height: 20),
                    _buildStartRunningButton(isTracking, context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Implements an adaptive time selection slider that automatically adjusts its range
  // based on the selected distance. Provides real-time feedback with formatted time display.
  Widget _buildTimeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Slider(
          value: selectedTime,
          min: minTime,
          max: maxTime,
          divisions: (maxTime - minTime).toInt(),
          label: _formatTime(selectedTime),
          onChanged: (value) {
            setState(() {
              selectedTime = value;
            });
          },
        ),
        _buildSelectedText("Selected time: ${_formatTime(selectedTime)}"),
      ],
    );
  }

  Widget _buildStepIndicator(String step, String title) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white
            .withOpacity(0.8), // Soft white background with transparency
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Light shadow for depth
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 101, 99, 97)
                  .withOpacity(0.9), // Orange accent for step
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedGoalCards() {
    final distanceUnit = ref.watch(distanceUnitProvider);
    final unitLabel = distanceUnit == DistanceUnit.kilometers ? 'km' : 'mi';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSingleGoalCard(
            'Selected Distance',
            selectedDistance != null
                ? '${selectedDistance!.toStringAsFixed(2)} $unitLabel'
                : '---'),
        _buildSingleGoalCard('Selected \nTime',
            selectedTime > 0 ? _formatTime(selectedTime) : '---'),
      ],
    );
  }

  Widget _buildSingleGoalCard(String title, String content) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(16),
        height: 130,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE1DC),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              content,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalGoalCard() {
    final distanceUnit = ref.watch(distanceUnitProvider);
    final unitLabel = distanceUnit == DistanceUnit.kilometers ? 'km' : 'mi';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8), // Soft white background
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Your Running Goal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGoalMetric(
                'Distance',
                '${selectedDistance?.toStringAsFixed(2)} $unitLabel',
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey[300],
              ),
              _buildGoalMetric(
                'Target Time',
                _formatTime(selectedTime),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // _buildStartRunningButton
  Widget _buildStartRunningButton(bool isTracking, BuildContext context) {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFEC6D5E),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        onPressed: () {
          // Solo navegación, sin GPS validation
          final trackingNotifier = ref.read(trackingProvider.notifier);
          if (isTracking) {
            trackingNotifier.state = false;
            print(
                'Traveled distance: ${ref.read(distanceProvider).toStringAsFixed(2)} km');
          } else {
            trackingNotifier.state = true;
            ref.read(distanceProvider.notifier).state = 0.0;
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CurrentRun()),
          );
        },
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow),
            SizedBox(width: 8),
            Text(
              'Confirm Goal',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmDistanceButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(71, 255, 255, 255)
              .withOpacity(0.9), // Orange tone
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          shadowColor: Colors.black.withOpacity(0.1), // Subtle shadow
          elevation: 4, // Slight elevation for depth
        ),
        onPressed: () {
          if (selectedDistance != null) {
            final distanceUnit = ref.read(distanceUnitProvider);
            final unitLabel =
                distanceUnit == DistanceUnit.kilometers ? 'km' : 'mi';
            ref.read(customDistanceProvider.notifier).state = selectedDistance;
            setState(() {
              isDistanceConfirmed = true;
            });
            print(
                'Distance of: ${selectedDistance?.toStringAsFixed(2)} $unitLabel confirmed!');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a distance.'),
              ),
            );
          }
        },
        child: const Text(
          'Confirm Distance',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPaceButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent.withOpacity(0.9), // Orange tone
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          shadowColor: Colors.black.withOpacity(0.1), // Subtle shadow
          elevation: 4, // Slight elevation for depth
        ),
        onPressed: () {
          if (selectedDistance != null && selectedTime > 0) {
            final distanceUnit = ref.read(distanceUnitProvider);
            double normalizedDistance = distanceUnit == DistanceUnit.kilometers
                ? selectedDistance! / 1.60934
                : selectedDistance!;
            double selectedPaceInSeconds =
                (selectedTime * 60) / normalizedDistance;
            ref.read(customPaceProvider.notifier).state = selectedPaceInSeconds;
            setState(() {
              isTimeConfirmed = true;
            });
            final unitLabel =
                distanceUnit == DistanceUnit.kilometers ? 'km' : 'mi';
            print(
                'Pace of: ${selectedPaceInSeconds.toStringAsFixed(2)} sec/$unitLabel confirmed!');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select both distance and time.'),
              ),
            );
          }
        },
        child: const Text(
          'Confirm Time',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Custom time formatting utility that handles both hour and minute display.
  // Implements smart formatting logic to show appropriate units based on duration.
  // @param time The time in minutes to be formatted
  // @returns Formatted string in "X hr Y min" or "Y min" format
  String _formatTime(double time) {
    if (time <= 0) {
      return '---';
    }

    if (time >= 60) {
      final hours = time ~/ 60;
      final minutes = (time % 60).toInt();
      return '${hours}:${minutes.toString().padLeft(2, '0')}h';
    } else {
      return '${time.toInt()}min';
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
        textAlign: TextAlign.center, // Align centrally if needed
      ),
    );
  }

  Widget _buildSelectedText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildButtonWrap(List<Widget> buttons) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center, // Center the buttons for better look
      children: buttons,
    );
  }

  Widget _buildQuickButton(String label, double value) {
    final isSelected = selectedDistance == value;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.white : const Color(0xFFFEE1DC),
        foregroundColor: isSelected ? const Color(0xFFEC6D5E) : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
      ),
      onPressed: () {
        _handleDistanceSelection(value);
      },
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCustomButton(
    String label,
    TextEditingController controller,
    String hintText,
    Function(String) onSubmitted,
  ) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Enter custom value"),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: hintText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    final value = double.tryParse(controller.text);

                    if (value != null && value > 0 && value <= 999.99) {
                      // Check if distance is below recommended minimum
                      final distanceUnit = ref.read(distanceUnitProvider);
                      final minRecommended =
                          distanceUnit == DistanceUnit.kilometers ? 5.0 : 3.1;

                      if (value < minRecommended) {
                        // Show warning dialog first
                        Navigator.pop(context); // Close current dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("⚠️ Short Distance Warning"),
                            content: const Text(
                              "This run-mode works best for medium-long runs (5k+).\n\nDo you want to continue anyway?",
                              style: TextStyle(fontSize: 16),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(
                                      context); // Close warning dialog
                                  onSubmitted(controller
                                      .text); // Proceed with selection
                                },
                                child: const Text("Continue Anyway"),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Distance is fine, proceed normally
                        onSubmitted(controller.text);
                        Navigator.pop(context);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please enter a reasonable distance (0.01 - 999.99)'),
                        ),
                      );
                    }
                  }
                },
                child: const Text("Confirm"),
              ),
            ],
          ),
        );
      },
      child: Text(label),
    );
  }

  // Processes distance selection and updates related state variables.
  // Implements validation and unit conversion logic while maintaining UI consistency.
  // @param distance The selected distance in current unit system
  void _handleDistanceSelection(double distance) {
    setState(() {
      selectedDistance = distance;

      if (distance < 3.1) {
        // Changed from 1.0 to 3.1 to handle custom distances under 5k
        minTime = 1;
        maxTime = 40; // Increased max time for distances under 5k
      } else {
        final times = _getDefaultTimesForCustomDistance(distance);
        minTime = times['min']!;
        maxTime = times['max']!;
      }

      selectedTime = minTime;
    });
  }

  // Calculates appropriate time ranges for different distances using a mapping algorithm.
  // Handles both metric and imperial units with custom logic for marathon distances.
  // @param distance The selected distance in current unit system
  // @returns Map containing minimum and maximum suggested times
  Map<String, double> _getDefaultTimesForCustomDistance(double distance) {
    final distanceUnit = ref.watch(distanceUnitProvider);

    final List<Map<String, dynamic>> defaultDistances = [
      // {'distance': 1.0, 'min': 4.0, 'max': 15.0}, // Commented out 1k/1mi
      {'distance': 3.1, 'min': 12.0, 'max': 40.0}, // Now starts from 5k/3.1mi
      {'distance': 6.2, 'min': 26.0, 'max': 80.0},
      {'distance': 13.1, 'min': 57.0, 'max': 210.0},
      {'distance': 26.2, 'min': 120.0, 'max': 390.0},
    ];

    if (distanceUnit == DistanceUnit.kilometers && distance == 42.2) {
      return {'min': 120.0, 'max': 390.0};
    }

    for (int i = 0; i < defaultDistances.length - 1; i++) {
      final current = defaultDistances[i];
      final next = defaultDistances[i + 1];

      if (distance >= current['distance'] && distance < next['distance']) {
        return {'min': current['min'], 'max': next['max']};
      }
    }

    // For custom distances below 5k/3.1mi, provide reasonable defaults
    if (distance < 3.1) {
      return {'min': 1.0, 'max': 40.0};
    }

    return {'min': 1.0, 'max': 390.0};
  }
}

// Application-wide color scheme definition using a HashMap for consistent theming
// and easy maintenance. Colors are optimized for accessibility and visual appeal.
final appColors = {
  'background': const Color(0xFFEC6D5E), // Coral/salmon
  'cardBackground': const Color(0xFFFEE1DC), // Light pink/peach
  'textPrimary': Colors.white,
  'textSecondary': Colors.black87,
  'accent': Colors.white,
};
