import 'package:flutter/material.dart';

class ResultScreen extends StatefulWidget {
  final String winner; // 'WEREWOLVES' or 'VILLAGERS'
  final List<ResultPlayer> players;

  const ResultScreen({
    super.key,
    required this.winner,
    required this.players,
  });

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isWerewolfWin = widget.winner == 'WEREWOLVES';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isWerewolfWin
                ? [Color(0xFF8B0000), Color(0xFF2D1B4E), Color(0xFF0F0A1E)]
                : [Color(0xFF2E7D32), Color(0xFF2D1B4E), Color(0xFF0F0A1E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 60),
              _buildWinnerAnnouncement(isWerewolfWin),
              SizedBox(height: 40),
              _buildPlayerStats(),
              Spacer(),
              _buildBottomButtons(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerAnnouncement(bool isWerewolfWin) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            children: [
              Text(
                isWerewolfWin ? '🐺' : '🏆',
                style: TextStyle(fontSize: 100),
              ),
              SizedBox(height: 16),
              Text(
                isWerewolfWin ? 'Werewolves Win!' : 'Villagers Win!',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                isWerewolfWin
                    ? 'The village has fallen to darkness'
                    : 'The village is saved!',
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerStats() {
    return Expanded(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Card(
          margin: EdgeInsets.all(16),
          color: Color(0xFF1A0F2E),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Final Results',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 20,
                    color: Color(0xFFC0C0D8),
                  ),
                ),
              ),
              Divider(color: Color(0xFFC0C0D8).withOpacity(0.3)),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: widget.players.length,
                  itemBuilder: (context, index) {
                    return _buildPlayerRow(widget.players[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerRow(ResultPlayer player) {
    Color roleColor;
    String roleIcon;

    switch (player.role) {
      case 'WEREWOLF':
        roleColor = Color(0xFF8B0000);
        roleIcon = '🐺';
        break;
      case 'SEER':
        roleColor = Color(0xFFD4AF37);
        roleIcon = '🔮';
        break;
      default:
        roleColor = Color(0xFF2E7D32);
        roleIcon = '👤';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: player.survived ? Color(0xFF2E7D32) : Color(0xFF424242),
            ),
            child: Center(
              child: Text(
                player.username[0].toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.username,
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 16,
                    color: Color(0xFFC0C0D8),
                  ),
                ),
                Text(
                  player.survived ? 'Survived' : 'Eliminated',
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 12,
                    color: player.survived
                        ? Color(0xFF2E7D32)
                        : Color(0xFF424242),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: roleColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(roleIcon, style: TextStyle(fontSize: 16)),
                SizedBox(width: 4),
                Text(
                  player.role,
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 12,
                    color: roleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Color(0xFFC0C0D8)),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Back to Lobby',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  color: Color(0xFFC0C0D8),
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Play Again',
                style: TextStyle(fontFamily: 'Cinzel'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ResultPlayer {
  final String username;
  final String role;
  final bool survived;

  ResultPlayer({
    required this.username,
    required this.role,
    required this.survived,
  });
}