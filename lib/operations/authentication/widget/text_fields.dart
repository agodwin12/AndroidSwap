import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final ValueChanged<String>? onChanged;  // ✅ Make `onChanged` nullable

  const CustomTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.onChanged,  // ✅ Now `onChanged` is optional
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,  // ✅ No error if `onChanged` is null
    );
  }
}
