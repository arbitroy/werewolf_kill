import 'package:flutter/material.dart';

class PhaseIndicatorWidget extends StatelessWidget {
  final bool isNight;
  final int timeRemaining;

  const PhaseIndicatorWidget({
    super.key,
    required this.isNight,
    required this.timeRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNight ? Color(0xFFC0C0D8) : Color(0xFFFFE4B5),
          width: 2,
        ),
        boxShadow: isNight
            ? [
                BoxShadow(
                  color: Color(0xFFC0C0D8).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNight ? Icons.nightlight_round : Icons.wb_sunny,
            color: isNight ? Color(0xFFC0C0D8) : Colors.orange,
            size: 28,
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isNight ? 'Night Phase' : 'Day Phase',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Color(0xFFC0C0D8) : Colors.white,
                ),
              ),
              Text(
                '$timeRemaining seconds',
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 14,
                  color: isNight
                      ? Color(0xFFC0C0D8).withOpacity(0.8)
                      : Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}