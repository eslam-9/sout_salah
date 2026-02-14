import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: 350,
    decoration: const BoxDecoration(
      color: Color(0xFFF1F8E9),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: const Icon(Icons.mosque, size: 60, color: Color(0xFF2D6930)),
        ),
        const SizedBox(height: 16),
        Text(
          'أهلاً بك',
          style: GoogleFonts.cairo(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B1B1B),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'قم بتسجيل الدخول للاستماع إلى تلاوات المسجد',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
        const Spacer(),
      ],
    ),
  );
}
