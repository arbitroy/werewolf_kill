import 'package:flutter/material.dart';

class PlayerAvatar extends StatelessWidget {
  final String username;
  final bool isAlive;
  final bool isSelected;
  final VoidCallback? onTap;
  final double size;

  const PlayerAvatar({
    super.key,
    required this.username,
    required this.isAlive,
    this.isSelected = false,
    this.onTap,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAlive ? onTap : null,
      child: Column(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAlive ? Color(0xFF2E7D32) : Color(0xFF424242),
              border: Border.all(
                color: isSelected
                    ? Color(0xFFD4AF37)
                    : (isAlive ? Color(0xFF4CAF50) : Color(0xFF757575)),
                width: isSelected ? 4 : 3,
              ),
              boxShadow: isAlive && !isSelected
                  ? [
                      BoxShadow(
                        color: Color(0xFF2E7D32).withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : (isSelected
                      ? [
                          BoxShadow(
                            color: Color(0xFFD4AF37).withOpacity(0.6),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ]
                      : []),
            ),
            child: Center(
              child: Text(
                username[0].toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              username,
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 12,
                color: isAlive ? Color(0xFFC0C0D8) : Color(0xFF757575),
              ),
            ),
          ),
        ],
      ),
    );
  }
}