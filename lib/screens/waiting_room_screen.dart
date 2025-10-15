import 'package:flutter/material.dart' hide ConnectionState;
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../core/models/player.dart';
import '../core/services/websocket_service.dart';

class WaitingRoomScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final bool isHost;

  const WaitingRoomScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.isHost,
  });

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  @override
  void initState() {
    super.initState();
    // Delay connection until after first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToRoom();
    });
  }

  void _connectToRoom() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      final myPlayer = Player(
        id: authProvider.currentUser!.id,
        username: authProvider.currentUser!.username,
      );

      print('🔵 Connecting to room via WebSocket: ${widget.roomId}');
      gameProvider.connectToRoom(widget.roomId, myPlayer);
    }
  }

  @override
  void dispose() {
    // Disconnect when leaving the room
    Provider.of<GameProvider>(context, listen: false).disconnectFromRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final players = gameProvider.players;
        final canStart = widget.isHost && players.length >= 3;
        final isConnected = gameProvider.isConnected;

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
                  _buildHeader(gameProvider.wsConnectionState),
                  SizedBox(height: 24),
                  _buildRoomInfo(players.length),
                  SizedBox(height: 32),
                  Expanded(child: _buildPlayerList(players)),
                  
                  // Error message
                  if (gameProvider.error != null)
                    _buildErrorMessage(gameProvider.error!),
                  
                  _buildBottomBar(canStart, isConnected, gameProvider.isLoading),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ConnectionState connectionState) {
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
          _buildConnectionIndicator(connectionState),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator(ConnectionState state) {
    Color color;
    IconData icon;
    String tooltip;

    switch (state) {
      case ConnectionState.connected:
        color = Colors.green;
        icon = Icons.check_circle;
        tooltip = 'Connected';
        break;
      case ConnectionState.connecting:
      case ConnectionState.reconnecting:
        color = Colors.orange;
        icon = Icons.sync;
        tooltip = 'Connecting...';
        break;
      case ConnectionState.error:
        color = Colors.red;
        icon = Icons.error;
        tooltip = 'Connection Error';
        break;
      case ConnectionState.disconnected:
      default:
        color = Colors.grey;
        icon = Icons.cloud_off;
        tooltip = 'Disconnected';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildRoomInfo(int playerCount) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      color: Color(0xFF1A0F2E),
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
              '$playerCount/8 players',
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 16,
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (playerCount < 3)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Need ${3 - playerCount} more to start',
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

  Widget _buildPlayerList(List<Player> players) {
    if (players.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD4AF37),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isMe = player.id == authProvider.currentUser?.id;

        return Card(
          color: Color(0xFF1A0F2E),
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
                      color: isMe ? Color(0xFFD4AF37) : Color(0xFF2E7D32),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      player.username[0].toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                      Text(
                        player.username + (isMe ? ' (You)' : ''),
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC0C0D8),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ready',
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 14,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: Color(0xFF2E7D32),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool canStart, bool isConnected, bool isLoading) {
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
                onPressed: (canStart && isConnected && !isLoading)
                    ? _startGame
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canStart
                      ? Color(0xFF2E7D32)
                      : Color(0xFF424242),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        canStart
                            ? 'Start Game'
                            : 'Waiting for players... (min 3)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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

  Future<void> _startGame() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    print('🔵 Starting game...');
    final success = await gameProvider.startGame(widget.roomId);

    if (success && mounted) {
      print('✅ Game started successfully');
      // Navigate to game screen
      Navigator.pushReplacementNamed(
        context,
        '/game',
        arguments: {
          'roomId': widget.roomId,
        },
      );
    } else if (mounted && gameProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gameProvider.error!),
          backgroundColor: Color(0xFF8B0000),
        ),
      );
    }
  }

  void _showLeaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A0F2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Leave Room?',
          style: TextStyle(
            fontFamily: 'Cinzel',
            color: Color(0xFFC0C0D8),
          ),
        ),
        content: Text(
          'Are you sure you want to leave?',
          style: TextStyle(
            fontFamily: 'Lora',
            color: Color(0xFFC0C0D8).withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFC0C0D8)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to lobby
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B0000),
            ),
            child: Text('Leave'),
          ),
        ],
      ),
    );
  }
}