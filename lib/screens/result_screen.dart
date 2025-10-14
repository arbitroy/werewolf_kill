import 'package:flutter/material.dart';

import 'game_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final bool isHost;

  const WaitingRoomScreen({super.key, 
    required this.roomId,
    required this.roomName,
    required this.isHost,
  });

  @override
  _WaitingRoomScreenState createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  List<WaitingPlayer> players = [];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    // TODO: Subscribe to WebSocket for player join/leave events
  }

  void _loadPlayers() {
    setState(() {
      players = [
        WaitingPlayer(id: '1', username: 'Alice', isHost: true, isReady: true),
        WaitingPlayer(id: '2', username: 'Bob', isHost: false, isReady: true),
        WaitingPlayer(id: '3', username: 'Charlie', isHost: false, isReady: false),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final canStart = widget.isHost && players.length >= 3;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0A1E),
              Color(0xFF2D1B4E),
              Color(0xFF1A0F2E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 24),
              _buildRoomInfo(),
              SizedBox(height: 32),
              Expanded(child: _buildPlayerList()),
              _buildBottomBar(canStart),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFFC0C0D8)),
            onPressed: () => _showLeaveDialog(),
          ),
          Expanded(
            child: Center(
              child: Text(
                widget.roomName,
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC0C0D8),
                ),
              ),
            ),
          ),
          SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildRoomInfo() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.nightlight_round,
              size: 60,
              color: Color(0xFFD4AF37),
            ),
            SizedBox(height: 16),
            Text(
              'Waiting for players...',
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 18,
                color: Color(0xFFC0C0D8),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${players.length}/8 players',
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 16,
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (players.length < 3)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Need ${3 - players.length} more to start',
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 14,
                    color: Color(0xFFC0C0D8).withOpacity(0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: players.length,
      itemBuilder: (context, index) {
        return _buildPlayerCard(players[index]);
      },
    );
  }

  Widget _buildPlayerCard(WaitingPlayer player) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2D1B4E),
                border: Border.all(
                  color: player.isReady ? Color(0xFF2E7D32) : Color(0xFF424242),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  player.username[0].toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 24,
                    color: Color(0xFFC0C0D8),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        player.username,
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontSize: 16,
                          color: Color(0xFFC0C0D8),
                        ),
                      ),
                      if (player.isHost) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'HOST',
                            style: TextStyle(
                              fontFamily: 'Cinzel',
                              fontSize: 10,
                              color: Color(0xFF1A0F2E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    player.isReady ? 'Ready' : 'Not ready',
                    style: TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 14,
                      color: player.isReady 
                        ? Color(0xFF2E7D32) 
                        : Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              player.isReady ? Icons.check_circle : Icons.pending,
              color: player.isReady ? Color(0xFF2E7D32) : Color(0xFF424242),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool canStart) {
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
      child: widget.isHost
          ? SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: canStart ? _startGame : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canStart 
                    ? Color(0xFF2E7D32) 
                    : Color(0xFF424242),
                ),
                child: Text(
                  canStart ? 'Start Game' : 'Waiting for players...',
                ),
              ),
            )
          : Center(
              child: Text(
                'Waiting for host to start...',
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 16,
                  color: Color(0xFFC0C0D8).withOpacity(0.7),
                ),
              ),
            ),
    );
  }

  void _startGame() {
    // TODO: Call API to start game
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(roomId: widget.roomId),
      ),
    );
  }

  void _showLeaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A0F2E),
        title: Text(
          'Leave Room?',
          style: TextStyle(fontFamily: 'Cinzel', color: Color(0xFFC0C0D8)),
        ),
        content: Text(
          'Are you sure you want to leave?',
          style: TextStyle(fontFamily: 'Lora', color: Color(0xFFC0C0D8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Color(0xFFC0C0D8))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Leave room
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8B0000)),
            child: Text('Leave'),
          ),
        ],
      ),
    );
  }
}

class WaitingPlayer {
  final String id;
  final String username;
  final bool isHost;
  final bool isReady;

  WaitingPlayer({
    required this.id,
    required this.username,
    required this.isHost,
    required this.isReady,
  });
}