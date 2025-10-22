import 'package:flutter/material.dart';
import 'dart:async';

class HunterRevengeDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availableTargets;
  final int secondsRemaining;
  final Function(String targetId) onTargetSelected;

  const HunterRevengeDialog({
    Key? key,
    required this.availableTargets,
    required this.secondsRemaining,
    required this.onTargetSelected,
  }) : super(key: key);

  @override
  State<HunterRevengeDialog> createState() => _HunterRevengeDialogState();
}

class _HunterRevengeDialogState extends State<HunterRevengeDialog>
    with SingleTickerProviderStateMixin {
  String? _selectedTargetId;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = widget.secondsRemaining <= 5;
    
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissal
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8B0000),
                Color(0xFF2D1B4E),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUrgent ? Colors.red : Color(0xFFD4AF37),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: (isUrgent ? Colors.red : Color(0xFFD4AF37))
                    .withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isUrgent ? _pulseAnimation.value : 1.0,
                    child: child,
                  );
                },
                child: Column(
                  children: [
                    Text(
                      '🎯',
                      style: TextStyle(fontSize: 60),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'HUNTER\'S REVENGE',
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Timer
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUrgent ? Colors.red : Color(0xFFD4AF37),
                    width: 2,
                  ),
                ),
                child: Text(
                  '${widget.secondsRemaining} seconds',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isUrgent ? Colors.red : Colors.white,
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              
              Text(
                'Take one player down with you!',
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 24),
              
              // Target list
              Container(
                constraints: BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.availableTargets.length,
                  itemBuilder: (context, index) {
                    final target = widget.availableTargets[index];
                    final targetId = target['playerId'] as String;
                    final username = target['username'] as String;
                    final isSelected = _selectedTargetId == targetId;
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedTargetId = targetId;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(0xFF8B0000)
                                  : Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Color(0xFFD4AF37)
                                    : Colors.white.withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? Color(0xFFD4AF37)
                                      : Colors.white.withOpacity(0.6),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    username,
                                    style: TextStyle(
                                      fontFamily: 'Lora',
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.tablet,
                                    color: Color(0xFFD4AF37),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              SizedBox(height: 24),
              
              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedTargetId != null
                      ? () {
                          widget.onTargetSelected(_selectedTargetId!);
                          Navigator.of(context).pop();
                        }
                      : null,
                  icon: Icon(Icons.flash_on),
                  label: Text(
                    'TAKE THE SHOT',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTargetId != null
                        ? Color(0xFFD4AF37)
                        : Colors.grey,
                    foregroundColor: Color(0xFF1A0F2E),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}