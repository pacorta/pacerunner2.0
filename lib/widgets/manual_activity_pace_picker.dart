import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> pickManualActivityPace(
  BuildContext context, {
  int initialSeconds = 0,
  String initialUnit = 'mi',
}) {
  int minutes = (initialSeconds ~/ 60).clamp(0, 59);
  int seconds = (initialSeconds % 60).clamp(0, 59);
  String unit = initialUnit;

  return showModalBottomSheet<Map<String, dynamic>?>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(null),
                          child: const Text('Cancel'),
                        ),
                        const Text(
                          'Pace',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () {
                            final totalSeconds = minutes * 60 + seconds;
                            Navigator.of(ctx)
                                .pop({'seconds': totalSeconds, 'unit': unit});
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0),

                  // MM:SS Picker with unit as wheel option
                  SizedBox(
                    height: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Minutes (0-59)
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

                        // Unit as wheel option (/mi or /km)
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: unit == 'mi' ? 0 : 1,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (i) {
                              setState(() {
                                unit = i == 0 ? 'mi' : 'km';
                              });
                            },
                            children: const [
                              Center(
                                child: Text(
                                  '/mi',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                              Center(
                                child: Text(
                                  '/km',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
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
    },
  );
}
