import 'package:flutter/material.dart';

class RoleReveal extends StatefulWidget {
  final String role;
  final VoidCallback onComplete;

  const RoleReveal({super.key, 
    required this.role,
    required this.onComplete,
  });

  @override
  _RoleRevealState createState() => _RoleRevealState();
}

class _RoleRevealState extends State<RoleReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(Duration(seconds: 2), () {
        widget.onComplete();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * 3.14159; // pi radians
        final isBack = angle > 1.5708; // 90 degrees
        
        return Container(
          color: Colors.black.withOpacity(0.9),
          child: Center(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: Card(
                elevation: 20,
                child: Container(
                  width: 250,
                  height: 350,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _getRoleColors(),
                    ),
                  ),
                  child: isBack 
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(3.14159),
                        child: _buildRoleContent(),
                      )
                    : _buildCardBack(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardBack() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.help_outline,
          size: 80,
          color: Color(0xFFC0C0D8),
        ),
        SizedBox(height: 16),
        Text(
          'Your Role',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 24,
            color: Color(0xFFC0C0D8),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _getRoleIcon(),
          style: TextStyle(fontSize: 80),
        ),
        SizedBox(height: 16),
        Text(
          widget.role,
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          _getRoleDescription(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Lora',
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  List<Color> _getRoleColors() {
    switch (widget.role.toUpperCase()) {
      case 'WEREWOLF':
        return [Color(0xFF8B0000), Color(0xFF2D1B4E)];
      case 'SEER':
        return [Color(0xFFD4AF37), Color(0xFF2D1B4E)];
      default:
        return [Color(0xFF2E7D32), Color(0xFF2D1B4E)];
    }
  }

  String _getRoleIcon() {
    switch (widget.role.toUpperCase()) {
      case 'WEREWOLF': return '🐺';
      case 'SEER': return '🔮';
      default: return '👤';
    }
  }

  String _getRoleDescription() {
    switch (widget.role.toUpperCase()) {
      case 'WEREWOLF': return 'Eliminate villagers during the night';
      case 'SEER': return 'Investigate one player each night';
      default: return 'Find and vote out the werewolves';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}