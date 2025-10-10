import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<DateTime?> pickManualActivityDateTime(
  BuildContext context, {
  DateTime? initial,
}) {
  final now = DateTime.now();
  final initialDate = initial ?? now;
  DateTime selectedDate = initialDate;

  return showCupertinoModalPopup<DateTime?>(
    context: context,
    builder: (BuildContext context) {
      return Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(12),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade300,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(null),
                    ),
                    // ← REMOVIDO: El texto "Date & Time"
                    const SizedBox.shrink(), // Espaciador vacío
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text('OK'),
                      onPressed: () => Navigator.of(context).pop(selectedDate),
                    ),
                  ],
                ),
              ),

              // Native iOS Date Picker
              Expanded(
                child: CupertinoDatePicker(
                  backgroundColor: Colors.white,
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: initialDate,
                  minimumDate: DateTime(2015, 1, 30),
                  maximumDate: now,
                  minuteInterval: 1,
                  use24hFormat: false,
                  onDateTimeChanged: (DateTime newDate) {
                    selectedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
