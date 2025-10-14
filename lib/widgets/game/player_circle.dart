import 'package:flutter/material.dart';
import 'dart:math' as math;

class PlayerCircle extends StatelessWidget {
  final List<Widget> players;
  final double radius;

  const PlayerCircle({
    super.key,
    required this.players,
    this.radius = 120,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actualRadius = math.min(
          constraints.maxWidth * 0.4,
          constraints.maxHeight * 0.4,
        );

        return Stack(
          children: [
            // Center circle outline
            Center(
              child: Container(
                width: actualRadius * 2,
                height: actualRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFFC0C0D8).withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Position players around circle
            ...List.generate(players.length, (index) {
              final angle = (2 * math.pi * index) / players.length - math.pi / 2;
              final x = actualRadius * math.cos(angle);
              final y = actualRadius * math.sin(angle);

              return Positioned(
                left: constraints.maxWidth / 2 + x - 35,
                top: constraints.maxHeight / 2 + y - 35,
                child: players[index],
              );
            }),
          ],
        );
      },
    );
  }
}