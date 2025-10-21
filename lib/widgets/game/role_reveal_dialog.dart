import 'package:flutter/material.dart';

class RoleRevealDialog extends StatelessWidget {
  final String role;
  final String roleDescription;
  final VoidCallback onContinue;

  const RoleRevealDialog({
    Key? key,
    required this.role,
    required this.roleDescription,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissal
      child: Dialog(
        backgroundColor: Color(0xFF1A0F2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🎭 Your Role',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 24,
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getRoleColor(role).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _getRoleColor(role), width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      role,
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 32,
                        color: _getRoleColor(role),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      roleDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 16,
                        color: Color(0xFFC0C0D8),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD4AF37),
                  foregroundColor: Color(0xFF1A0F2E),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue to Game',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'WEREWOLF':
        return Color(0xFF8B0000);
      case 'SEER':
        return Color(0xFF4B0082);
      case 'DOCTOR':
        return Color(0xFF2E7D32);
      case 'HUNTER':
        return Color(0xFFD84315);
      default:
        return Color(0xFFC0C0D8);
    }
  }
}