import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//manual_activity_distance_picker.dart
/// Distance picker with km/mi as wheel options (like screenshot)
/// Returns a map with 'value' (double) and 'unit' (String: 'mi' or 'km')
Future<Map<String, dynamic>?> pickManualActivityDistance(
  BuildContext context, {
  double initialValue = 0.0,
  String initialUnit = 'mi',
}) {
  int whole = initialValue.floor().clamp(0, 999);
  int decimal = ((initialValue - whole) * 10).round().clamp(0, 9);
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
                          'Distance',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () {
                            final value = whole + decimal / 10.0;
                            Navigator.of(ctx)
                                .pop({'value': value, 'unit': unit});
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0),

                  // Distance picker with unit as wheel option (like screenshot)
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        // Whole number (0-999)
                        Expanded(
                          flex: 2,
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: whole,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (i) => whole = i,
                            children: List.generate(
                              1000,
                              (i) => Center(
                                child: Text(
                                  '$i',
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Decimal point
                        Container(
                          width: 20,
                          alignment: Alignment.center,
                          child: const Text(
                            '.',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),

                        // Decimal (0-9)
                        Expanded(
                          flex: 1,
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: decimal,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (i) => decimal = i,
                            children: List.generate(
                              10,
                              (i) => Center(
                                child: Text(
                                  '$i',
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Unit as wheel option (km/mi)
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
                                  'mi',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                              Center(
                                child: Text(
                                  'km',
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
