import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatelessWidget {
  final String hint, label;
  final TextEditingController ctrl;
  final bool pass;
  final Widget? suf;
  const CustomTextField({
    super.key,
    required this.hint,
    required this.ctrl,
    required this.label,
    this.pass = false,
    this.suf,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        obscureText: pass,
        textAlign: TextAlign.end,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(color: Colors.grey),
          suffixIcon: suf,
          contentPadding: const EdgeInsets.all(16),
          filled: true,
          fillColor: Colors.white,
          border: _b(Colors.grey.shade300),
          enabledBorder: _b(Colors.grey.shade300),
          focusedBorder: _b(const Color(0xFF2D6930), 2),
        ),
      ),
    ],
  );
  InputBorder _b(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c, width: w),
  );
}
