import 'package:flutter/material.dart';

class ErrorDialog {
  static void show(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A0F2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Color(0xFF8B0000)),
            SizedBox(width: 12),
            Text(
              'Error',
              style: TextStyle(
                fontFamily: 'Cinzel',
                color: Color(0xFFC0C0D8),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Lora',
            color: Color(0xFFC0C0D8),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2D1B4E),
            ),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}