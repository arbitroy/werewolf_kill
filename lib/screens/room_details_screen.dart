import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/room_provider.dart';
import '../providers/auth_provider.dart';
import '../core/models/room.dart';
import '../core/models/player.dart';

class RoomDetailsScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const RoomDetailsScreen({
    Key? key,
    required this.roomId,
    required this.roomName,
  }) : super(key: key);

  @override
  _RoomDetailsScreenState createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  @override
  void initState() {
    super.initState();
    _loadRoomDetails();
  }

  Future<void> _loadRoomDetails() async {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    await roomProvider.getRoomDetails(widget.roomId);
    await roomProvider.getRoomPlayers(widget.roomId);
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
                color: Color(0xFFC0C0D8).withOpacity(0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFFC0C0D8)),
            onPressed: _loadRoomDetails,
          ),
          IconButton(
            icon: Icon(Icons.share, color: Color(0xFFC0C0D8)),
            onPressed: _shareRoomId,
          ),
        ],
      ),
      body: Consumer<RoomProvider>(
        builder: (context, roomProvider, child) {
          final room = roomProvider.currentRoom;
          final players = roomProvider.roomPlayers;
          final isLoading = roomProvider.isLoading;
          final error = roomProvider.error;

          if (isLoading && players.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          }

          if (error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Color(0xFF8B0000)),
                  SizedBox(height: 16),
                  Text(
                    'Error loading room',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 18,
                      color: Color(0xFFC0C0D8),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    error,
                    style: TextStyle(color: Color(0xFFC0C0D8).withOpacity(0.6)),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadRoomDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2E7D32),
                    ),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadRoomDetails,
            color: Color(0xFFD4AF37),
            backgroundColor: Color(0xFF1A0F2E),
            child: CustomScrollView(
              slivers: [
                // Room Info Card
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A0F2E), Color(0xFF2A1F3E)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFFD4AF37).withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
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
                            _buildStatusChip(room?.status ?? 'WAITING'),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoItem(
                              'Players',
                              '${room?.currentPlayers ?? 0}/${room?.maxPlayers ?? 8}',
                              Icons.people,
                            ),
                            _buildInfoItem(
                              'Min to Start',
                              '3 players',
                              Icons.flag,
                            ),
                          ],
                        ),
                        if (room?.canStart == true && players.length >= 3)
                          Container(
                            margin: EdgeInsets.only(top: 16),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF2E7D32).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFF2E7D32),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF2E7D32),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Ready to start!',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
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
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final player = players[index];
                    return _buildPlayerTile(player);
                  }, childCount: players.length),
                ),

                // Empty State
                if (players.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Color(0xFFC0C0D8).withOpacity(0.3),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No players yet',
                            style: TextStyle(
                              fontFamily: 'Cinzel',
                              fontSize: 18,
                              color: Color(0xFFC0C0D8).withOpacity(0.5),
                            ),
                          ),
                          Text(
                            'Waiting for players to join...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFC0C0D8).withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'WAITING':
        color = Color(0xFFFFA500);
        icon = Icons.hourglass_empty;
        break;
      case 'IN_PROGRESS':
        color = Color(0xFF2E7D32);
        icon = Icons.play_arrow;
        break;
      case 'FINISHED':
        color = Color(0xFF8B0000);
        icon = Icons.done;
        break;
      default:
        color = Color(0xFFC0C0D8);
        icon = Icons.help_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
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
        Icon(icon, color: Color(0xFFC0C0D8).withOpacity(0.6), size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFC0C0D8).withOpacity(0.6),
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

  Widget _buildPlayerTile(Player player) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isMe = player.id == authProvider.currentUser?.id;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0F2E).withOpacity(0.8),
            Color(0xFF2A1F3E).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? Color(0xFFD4AF37).withOpacity(0.5)
              : Color(0xFFC0C0D8).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF2A1F3E),
          child: player.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    player.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        player.username[0].toUpperCase(),
                        style: TextStyle(
                          color: Color(0xFFC0C0D8),
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                )
              : Text(
                  player.username[0].toUpperCase(),
                  style: TextStyle(
                    color: Color(0xFFC0C0D8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Row(
          children: [
            Text(
              player.username,
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 16,
                color: Color(0xFFC0C0D8),
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isMe)
              Container(
                margin: EdgeInsets.only(left: 8),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFFD4AF37).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'You',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: player.role != null
            ? Text(
                player.role!,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFC0C0D8).withOpacity(0.6),
                ),
              )
            : null,
        trailing: player.isHost
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFFD4AF37).withOpacity(0.2),
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final roomProvider = Provider.of<RoomProvider>(context);
    final room = roomProvider.currentRoom;
    final isHost = room?.createdBy == authProvider.currentUser?.id;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A0F2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
                onPressed: () => _leaveRoom(),
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
            if (isHost) ...[
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: (room?.canStart == true) ? _startGame : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E7D32),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    room?.canStart == true ? 'Start Game' : 'Need 3+ Players',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _shareRoomId() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room ID: ${widget.roomId}'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // Implement copy to clipboard
          },
        ),
      ),
    );
  }

  void _leaveRoom() async {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

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
          style: TextStyle(color: Color(0xFFC0C0D8).withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
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
      // ✅ Proper leave flow
      final gameProvider = Provider.of<GameProvider>(context, listen: false);

      // If connected via WebSocket, use that
      if (gameProvider.isConnected &&
          gameProvider.currentRoomId == widget.roomId) {
        await gameProvider.leaveRoom();
      } else {
        // Otherwise, just call REST API for cleanup
        final roomProvider = Provider.of<RoomProvider>(context, listen: false);
        await roomProvider.leaveRoom(
          widget.roomId,
          authProvider.currentUser!.id,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _startGame() {
    // Navigate to game screen or trigger game start
    Navigator.pushReplacementNamed(
      context,
      '/game',
      arguments: {'roomId': widget.roomId},
    );
  }
}
