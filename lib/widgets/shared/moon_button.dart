import 'package:flutter/material.dart';

class MoonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isLoading;

  const MoonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Color(0xFF2D1B4E),
          foregroundColor: textColor ?? Color(0xFFC0C0D8),
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor ?? Color(0xFFC0C0D8),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}