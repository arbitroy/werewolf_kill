import 'package:flutter/material.dart';

class VotePanel extends StatelessWidget {
  final String? selectedPlayerId;
  final VoidCallback onVote;
  final bool isVoting;

  const VotePanel({
    Key? key,
    this.selectedPlayerId,
    required this.onVote,
    this.isVoting = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A0F2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedPlayerId != null 
              ? 'Confirm your vote' 
              : 'Select a player to vote',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 16,
              color: Color(0xFFC0C0D8),
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: selectedPlayerId != null && !isVoting ? onVote : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedPlayerId != null 
                  ? Color(0xFF8B0000) 
                  : Color(0xFF424242),
              ),
              child: isVoting
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      selectedPlayerId != null ? 'Cast Vote' : 'Select Player First',
                      style: TextStyle(fontFamily: 'Cinzel'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}