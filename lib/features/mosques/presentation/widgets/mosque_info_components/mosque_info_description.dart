import 'package:flutter/material.dart';
import '../../../domain/entities/mosque.dart';

class MosqueInfoDescription extends StatelessWidget {
  final Mosque mosque;

  const MosqueInfoDescription({super.key, required this.mosque});

  @override
  Widget build(BuildContext context) {
    if (mosque.description == null || mosque.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          mosque.description!,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }
}
