import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool outline;
  final Widget? icon;
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.outline = false,
    this.icon,
  });
  @override
  Widget build(BuildContext context) {
    var c = outline ? const Color(0xFF2D6930) : Colors.white;
    var s = outline
        ? OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF2D6930), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D6930),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          );
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: outline
          ? OutlinedButton(onPressed: onPressed, style: s, child: _c(c))
          : ElevatedButton(onPressed: onPressed, style: s, child: _c(c)),
    );
  }

  Widget _c(Color c) {
    var t = Text(
      text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c),
    );
    return icon != null
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              t,
              const SizedBox(width: 8),
              IconTheme(
                data: IconThemeData(color: c),
                child: icon!,
              ),
            ],
          )
        : t;
  }
}
