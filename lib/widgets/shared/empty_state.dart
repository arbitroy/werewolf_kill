import 'package:flutter/material.dart';

import 'moon_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Color(0xFFC0C0D8).withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 20,
                color: Color(0xFFC0C0D8).withOpacity(0.7),
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 14,
                color: Color(0xFFC0C0D8).withOpacity(0.5),
              ),
            ),
            if (actionText != null && onAction != null) ...[
              SizedBox(height: 24),
              MoonButton(
                text: actionText!,
                onPressed: onAction,
                backgroundColor: Color(0xFF2E7D32),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
