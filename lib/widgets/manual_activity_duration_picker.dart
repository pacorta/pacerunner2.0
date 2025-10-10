import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//manual_activity_duration_picker.dart
/// Extended duration picker: HH:MM:SS with range 00:00:00 to 99:59:59
Future<Duration?> pickManualActivityDuration(
  BuildContext context, {
  Duration initial = Duration.zero,
}) {
  int hours = initial.inHours.clamp(0, 99);
  int minutes = (initial.inMinutes % 60).clamp(0, 59);
  int seconds = (initial.inSeconds % 60).clamp(0, 59);

  return showModalBottomSheet<Duration?>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(null),
                      child: const Text('Cancel'),
                    ),
                    const Text(
                      'Duration',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    TextButton(
                      onPressed: () {
                        final duration = Duration(
                          hours: hours,
                          minutes: minutes,
                          seconds: seconds,
                        );
                        Navigator.of(ctx).pop(duration);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),

              // HH:MM:SS Picker
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    // Hours (00-99)
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: hours,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => hours = i,
                        children: List.generate(
                          100,
                          (i) => Center(
                            child: Text(
                              i.toString().padLeft(2, '0'),
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text(':',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),

                    // Minutes (00-59)
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: minutes,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => minutes = i,
                        children: List.generate(
                          60,
                          (i) => Center(
                            child: Text(
                              i.toString().padLeft(2, '0'),
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text(':',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),

                    // Seconds (00-59)
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: seconds,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => seconds = i,
                        children: List.generate(
                          60,
                          (i) => Center(
                            child: Text(
                              i.toString().padLeft(2, '0'),
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
}
