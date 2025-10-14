import 'package:flutter/material.dart';

class PhaseTransition extends StatefulWidget {
  final bool isNight;
  final VoidCallback onComplete;

  PhaseTransition({
    required this.isNight,
    required this.onComplete,
  });

  @override
  _PhaseTransitionState createState() => _PhaseTransitionState();
}

class _PhaseTransitionState extends State<PhaseTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        widget.onComplete();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(_fadeAnimation.value * 0.8),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isNight ? Icons.nightlight_round : Icons.wb_sunny,
                      size: 120,
                      color: widget.isNight 
                        ? Color(0xFFC0C0D8) 
                        : Colors.orange,
                    ),
                    SizedBox(height: 24),
                    Text(
                      widget.isNight ? 'Night Falls' : 'Day Breaks',
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: widget.isNight 
                          ? Color(0xFFC0C0D8) 
                          : Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      widget.isNight 
                        ? 'Special roles act now...' 
                        : 'Discuss and vote!',
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 18,
                        color: widget.isNight 
                          ? Color(0xFFC0C0D8).withOpacity(0.8) 
                          : Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}