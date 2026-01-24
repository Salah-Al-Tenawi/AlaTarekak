import 'package:flutter/material.dart';

class DatePickerService {
  static Future<DateTime?> showCustomDateTimePicker({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    Color? primaryColor,
    Color? onPrimaryColor,
  }) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime.now(),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor ?? Colors.blue,
              onPrimary: onPrimaryColor ?? Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return null;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor ?? Colors.blue,
              onPrimary: onPrimaryColor ?? Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return null; 

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }
}