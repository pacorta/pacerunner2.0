import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<double?> pickDistance(BuildContext context, {double initial = 0.0}) {
  int whole = initial.floor();
  int decimal = ((initial - whole) * 10).round();

  return showModalBottomSheet<double>(
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
              // Barra de título
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
                    const Text('Distance',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () {
                        final value = whole + decimal / 10.0;
                        Navigator.of(ctx).pop(value);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),

              // Pickers lado a lado - solo entero y decimal
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    // Picker para números enteros (0-99)
                    Expanded(
                      flex: 2,
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: whole.clamp(0, 99)),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => whole = i,
                        children: List.generate(
                            100,
                            (i) => Center(
                                child: Text('$i',
                                    style: const TextStyle(fontSize: 22)))),
                      ),
                    ),

                    // Punto decimal visual
                    Container(
                      width: 20,
                      alignment: Alignment.center,
                      child: const Text('.',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ),

                    // Picker para decimales (0-9)
                    Expanded(
                      flex: 1,
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: decimal.clamp(0, 9)),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => decimal = i,
                        children: List.generate(
                            10,
                            (i) => Center(
                                child: Text('$i',
                                    style: const TextStyle(fontSize: 22)))),
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
