import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'distance_unit_provider.dart';

class PaceSelectionWidget extends ConsumerStatefulWidget {
  final Function(double, double)? onConfirm; // Collects distance and pace.

  const PaceSelectionWidget({
    Key? key,
    this.onConfirm,
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

  @override
  Widget build(BuildContext context) {
    final distanceUnit = ref.watch(distanceUnitProvider);
    final unitLabel = distanceUnit == DistanceUnit.kilometers ? 'km' : 'mi';
    final distances = distanceUnit == DistanceUnit.kilometers
        ? [1.0, 5.0, 10.0, 21.1, 42.2]
        : [1.0, 3.1, 6.2, 13.1, 26.2];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select Your Pace'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                context,
                "What's your target distance in $unitLabel?",
              ),
              const SizedBox(height: 10),
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
                  (value) => _handleDistanceSelection(double.parse(value)),
                ))),
              if (selectedDistance != null)
                _buildSelectedText(
                    "Selected distance: $selectedDistance $unitLabel"),
              const SizedBox(height: 30),
              if (selectedDistance != null) _buildTimeSlider(),
              const SizedBox(height: 30),
              _buildConfirmButton(), // Confirm button at the end
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, "Select your target time"),
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

  Widget _buildConfirmButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: () {
          // Ensure both distance and time are selected before confirming.
          if (selectedDistance != null && selectedTime > 0) {
            double selectedPaceInSeconds =
                (selectedTime * 60) / selectedDistance!; // Convert to seconds
            widget.onConfirm?.call(selectedDistance!, selectedPaceInSeconds);
            print("Selected Pace in Seconds: $selectedPaceInSeconds");
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select both distance and time.'),
              ),
            );
          }
        },
        child: const Text(
          'Confirm',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  String _formatTime(double time) {
    if (time >= 60) {
      final hours = time ~/ 60;
      final minutes = (time % 60).toInt();
      return '$hours hr ${minutes.toString().padLeft(2, '0')} min';
    } else {
      return '${time.toInt()} min';
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
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
      children: buttons,
    );
  }

  Widget _buildQuickButton(String label, double value) {
    final isSelected = selectedDistance == value;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blueAccent : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      onPressed: () {
        _handleDistanceSelection(value);
      },
      child: Text(label),
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
                    onSubmitted(controller.text);
                    Navigator.pop(context);
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

  void _handleDistanceSelection(double distance) {
    setState(() {
      selectedDistance = distance;

      if (distance < 1.0) {
        minTime = 1;
        maxTime = 15;
      } else {
        final times = _getDefaultTimesForCustomDistance(distance);
        minTime = times['min']!;
        maxTime = times['max']!;
      }

      selectedTime = minTime;
    });
  }

  Map<String, double> _getDefaultTimesForCustomDistance(double distance) {
    final distanceUnit = ref.watch(distanceUnitProvider);

    final List<Map<String, dynamic>> defaultDistances = [
      {'distance': 1.0, 'min': 4.0, 'max': 15.0},
      {'distance': 3.1, 'min': 12.0, 'max': 40.0},
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

    return {'min': 1.0, 'max': 390.0};
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }
}
