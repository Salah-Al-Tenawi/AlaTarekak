// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:alatarekak/core/them/my_colors.dart';

class MyDropdown extends StatelessWidget {
  final String title;
  final String? selectedValue;
  final List<String> options;
  final String? Function(String?)? validator;
  final Widget? icon;
  final Function(String?) onChanged;

  const MyDropdown({
    super.key,
    required this.title,
    required this.selectedValue,
    required this.options,
    required this.validator,
    this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: MyColors.primary)),
          labelText: title,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        value: options.contains(selectedValue) ? selectedValue : null,
        items: options.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (value) {
          onChanged(value);
        },
        validator: validator,
        icon: icon,
      ),
    );
  }
}
