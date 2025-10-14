import 'package:flutter/material.dart';

import 'village_card.dart';

class LoadingOverlay extends StatelessWidget {
  final String message;

  const LoadingOverlay({
    super.key,
    this.message = 'Loading...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: VillageCard(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFD4AF37),
              ),
              SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 16,
                  color: Color(0xFFC0C0D8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}