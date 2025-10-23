import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../core/models/player.dart';

class RoomDetailsScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final bool isHost;

  const RoomDetailsScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    this.isHost = false,
  });

  @override
  _RoomDetailsScreenState createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Connect to WebSocket for real-time updates
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
        isHost: widget.isHost,
      );

      print('🔵 RoomDetails: Connecting to room via WebSocket: ${widget.roomId}');
      gameProvider.connectToRoom(widget.roomId, myPlayer);
    }
  }

  @override
  void dispose() {
    // Disconnect WebSocket when leaving screen
    try {
      if (mounted) {
        final gameProvider = context.read<GameProvider>();
        gameProvider.disconnectFromRoom();
      }
    } catch (e) {
      print('Provider already disposed: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0221),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A0F2E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.roomName,
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 20,
                color: Color(0xFFC0C0D8),
              ),
            ),
            Text(
              'Room ID: ${widget.roomId.substring(0, 8)}',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFC0C0D8).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Color(0xFFC0C0D8)),
            onPressed: _shareRoomId,
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          final players = gameProvider.players;
          final isConnected = gameProvider.isConnected;
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final myPlayerId = authProvider.currentUser?.id;

          // Determine if current user is host
          final myPlayer = players.firstWhere(
            (p) => p.id == myPlayerId,
            orElse: () => Player(
              id: myPlayerId ?? '',
              username: authProvider.currentUser?.username ?? 'Unknown',
              isHost: false,
            ),
          );
          final amIHost = myPlayer.isHost;

          return CustomScrollView(
            slivers: [
              // Connection Status
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isConnected 
                        ? Color(0xFF2E7D32).withValues(alpha: 0.2)
                        : Color(0xFF8B0000).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isConnected ? Color(0xFF2E7D32) : Color(0xFF8B0000),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected ? Colors.green : Colors.red,
                          boxShadow: isConnected
                              ? [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        isConnected ? 'Connected - Live Updates' : 'Connecting...',
                        style: TextStyle(
                          color: Color(0xFFC0C0D8).withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Room Info Card
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A0F2E), Color(0xFF2A1F3E)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(0xFFD4AF37).withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Room Status',
                            style: TextStyle(
                              fontFamily: 'Cinzel',
                              fontSize: 16,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                          _buildStatusChip('WAITING'),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoItem(
                            'Players',
                            '${players.length}/8',
                            Icons.people,
                          ),
                          _buildInfoItem(
                            'Status',
                            players.length >= 3 ? 'Ready' : 'Waiting',
                            Icons.check_circle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Players List Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Players (${players.length})',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 18,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ),
              ),

              // Players List
              if (players.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFD4AF37)),
                        SizedBox(height: 16),
                        Text(
                          'Waiting for players to connect...',
                          style: TextStyle(
                            color: Color(0xFFC0C0D8).withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final player = players[index];
                      return _buildPlayerTile(player, myPlayerId);
                    },
                    childCount: players.length,
                  ),
                ),

              // Bottom padding for button
              SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status.toUpperCase()) {
      case 'WAITING':
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case 'ACTIVE':
        color = Color(0xFF2E7D32);
        icon = Icons.play_circle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFFC0C0D8).withValues(alpha: 0.6), size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFC0C0D8).withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC0C0D8),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerTile(Player player, String? myPlayerId) {
    final isMe = player.id == myPlayerId;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0F2E).withValues(alpha: 0.8),
            Color(0xFF2A1F3E).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? Color(0xFFD4AF37).withValues(alpha: 0.5)
              : Color(0xFFC0C0D8).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF2A1F3E),
          child: Text(
            player.username[0].toUpperCase(),
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              player.username,
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 16,
                color: Color(0xFFC0C0D8),
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isMe) ...[
              SizedBox(width: 8),
              Text(
                '(You)',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD4AF37),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: player.isHost
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFFD4AF37).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFFD4AF37), width: 1),
                ),
                child: Text(
                  'HOST',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final players = gameProvider.players;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final myPlayerId = authProvider.currentUser?.id;
        
        final myPlayer = players.firstWhere(
          (p) => p.id == myPlayerId,
          orElse: () => Player(
            id: myPlayerId ?? '',
            username: authProvider.currentUser?.username ?? 'Unknown',
            isHost: false,
          ),
        );
        final amIHost = myPlayer.isHost;
        final canStart = players.length >= 3;

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF1A0F2E),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _leaveRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8B0000),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Leave Room',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (amIHost) ...[
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canStart ? _startGame : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2E7D32),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        canStart ? 'Start Game' : 'Need 3+ Players',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _shareRoomId() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room ID: ${widget.roomId}'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // TODO: Implement copy to clipboard
          },
        ),
        backgroundColor: Color(0xFF1A0F2E),
      ),
    );
  }

  void _leaveRoom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A0F2E),
        title: Text(
          'Leave Room?',
          style: TextStyle(fontFamily: 'Cinzel', color: Color(0xFFC0C0D8)),
        ),
        content: Text(
          'Are you sure you want to leave this room?',
          style: TextStyle(color: Color(0xFFC0C0D8).withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Color(0xFFC0C0D8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8B0000)),
            child: Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      
      // Use GameProvider's leave room which handles WebSocket disconnection
      await gameProvider.leaveRoom();

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _startGame() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    print('🎮 Starting game...');
    final success = await gameProvider.startGame();
    
    if (success && mounted) {
      print('✅ Game started successfully');
      // Navigation will happen automatically via GameProvider listener in waiting_room
      // Or navigate manually here:
      Navigator.pushReplacementNamed(
        context,
        '/waiting',
        arguments: {
          'roomId': widget.roomId,
          'roomName': widget.roomName,
          'isHost': true,
        },
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gameProvider.error ?? 'Failed to start game'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );
    }
  }
}