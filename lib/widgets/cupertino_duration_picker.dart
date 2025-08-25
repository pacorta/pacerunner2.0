import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<Duration?> pickCupertinoDuration(BuildContext context,
    {Duration initial = Duration.zero}) {
  Duration temp = initial;

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
              // Barra de título + acciones
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
                    const Text('Time',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(temp),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              // Timer picker with proper sizing
              SizedBox(
                height: 200,
                child: CupertinoTimerPicker(
                  mode:
                      CupertinoTimerPickerMode.hms, // horas, minutos, segundos
                  initialTimerDuration: initial,
                  onTimerDurationChanged: (d) => temp = d,
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
