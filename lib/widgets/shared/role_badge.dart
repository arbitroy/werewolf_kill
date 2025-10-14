import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  final bool isSmall;

  const RoleBadge({
    super.key,
    required this.role,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final roleData = _getRoleData(role);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: roleData['color'].withOpacity(0.2),
        borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
        border: Border.all(
          color: roleData['color'],
          width: isSmall ? 1 : 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            roleData['icon'],
            style: TextStyle(fontSize: isSmall ? 12 : 16),
          ),
          SizedBox(width: 4),
          Text(
            role,
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: isSmall ? 10 : 12,
              color: roleData['color'],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getRoleData(String role) {
    switch (role.toUpperCase()) {
      case 'WEREWOLF':
        return {
          'icon': '🐺',
          'color': Color(0xFF8B0000),
        };
      case 'SEER':
        return {
          'icon': '🔮',
          'color': Color(0xFFD4AF37),
        };
      case 'VILLAGER':
        return {
          'icon': '👤',
          'color': Color(0xFF2E7D32),
        };
      default:
        return {
          'icon': '❓',
          'color': Color(0xFF424242),
        };
    }
  }
}
