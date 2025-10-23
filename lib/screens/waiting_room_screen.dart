import 'package:flutter/material.dart' hide ConnectionState;
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../core/models/player.dart';
import '../widgets/game/role_reveal_dialog.dart';

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
  bool _roleRevealed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToRoom();
      _setupRoleRevealListener();
    });
  }

  void _setupRoleRevealListener() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    // ✅ Listen for role assignment
    gameProvider.onShowRoleReveal = (role, description) {
      if (mounted && !_roleRevealed) {
        _roleRevealed = true;
        _showRoleRevealDialog(role, description);
      }
    };
  }

  void _showRoleRevealDialog(String role, String description) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RoleRevealDialog(
        role: role,
        roleDescription: description,
        onContinue: () {
          Navigator.of(context).pop(); // Close dialog
          // Now navigate to game screen
          Navigator.pushReplacementNamed(
            context,
            '/game',
            arguments: {'roomId': widget.roomId},
          );
        },
      ),
    );
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

      print('🔵 Connecting to room via WebSocket: ${widget.roomId}');
      gameProvider.connectToRoom(widget.roomId, myPlayer);
    }
  }

  @override
  void dispose() {
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
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        // ✅ CHECK FOR GAME START AND AUTO-NAVIGATE
        final gameState = gameProvider.gameState;
        // if (gameState != null &&
        //     gameState.isActive &&
        //     (gameState.phase == 'STARTING' || gameState.phase == 'NIGHT')) {
        //   // Use WidgetsBinding to navigate after build completes
        //   WidgetsBinding.instance.addPostFrameCallback((_) {
        //     if (mounted) {
        //       print('🎮 Game started - Navigating to game screen');
        //       Navigator.pushReplacementNamed(
        //         context,
        //         '/game',
        //         arguments: {'roomId': widget.roomId},
        //       );
        //     }
        //   });
        // }

        final players = gameProvider.players;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // ✅ Determine if I'm the host from actual player state
        final myPlayer = players.firstWhere(
          (p) => p.id == authProvider.currentUser?.id,
          orElse: () => Player(
            id: authProvider.currentUser?.id ?? '',
            username: authProvider.currentUser?.username ?? '',
            isHost: false,
          ),
        );

        // ✅ Use actual host status from the player list
        final amIHost = myPlayer.isHost;
        final canStart = players.length >= 3 && amIHost;
        final isConnected = gameProvider.isConnected;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0A1F),
                  Color(0xFF1A0F2E),
                  Color(0xFF2D1B4E),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(widget.roomName, isConnected),
                  Expanded(
                    child: _buildPlayerList(
                      players,
                      authProvider.currentUser?.id,
                    ),
                  ),
                  if (gameProvider.error != null)
                    _buildErrorMessage(gameProvider.error!),
                  _buildBottomBar(
                    canStart,
                    isConnected,
                    gameProvider.isLoading,
                    amIHost,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String roomName, bool isConnected) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Connection indicator
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
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
                isConnected ? 'Connected' : 'Connecting...',
                style: TextStyle(
                  color: Color(0xFFC0C0D8).withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Room name
          Text(
            roomName,
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Waiting for players...',
            style: TextStyle(
              fontFamily: 'Lora',
              fontSize: 16,
              color: Color(0xFFC0C0D8).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(List<Player> players, String? myId) {
    if (players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFD4AF37)),
            SizedBox(height: 16),
            Text(
              'Waiting for players...',
              style: TextStyle(
                color: Color(0xFFC0C0D8).withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final isMe = player.id == myId;

        return _buildPlayerCard(player, isMe);
      },
    );
  }

  Widget _buildPlayerCard(Player player, bool isMe) {
    return Card(
      color: Color(0xFF1A0F2E),
      margin: EdgeInsets.only(bottom: 12),
      elevation: player.isHost ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: player.isHost
              ? Color(0xFFD4AF37)
              : (isMe
                    ? Color(0xFFD4AF37).withValues(alpha: 0.3)
                    : Colors.transparent),
          width: player.isHost ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // ✅ Avatar with host crown indicator
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: player.isHost
                        ? LinearGradient(
                            colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                          )
                        : LinearGradient(
                            colors: [Color(0xFF2D1B4E), Color(0xFF1A0F2E)],
                          ),
                    border: Border.all(
                      color: isMe ? Color(0xFFD4AF37) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      player.username.isNotEmpty
                          ? player.username[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: player.isHost
                            ? Color(0xFF1A0F2E)
                            : Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                ),
                // ✅ Crown icon for host
                if (player.isHost)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFD700),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFFD700).withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: Color(0xFF1A0F2E),
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 16),
            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        player.username + (isMe ? ' (You)' : ''),
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontSize: 18,
                          fontWeight: player.isHost
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Color(0xFFC0C0D8),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  // ✅ HOST BADGE - Prominent and clear
                  if (player.isHost)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFD4AF37).withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, color: Color(0xFF1A0F2E), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'HOST',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1A0F2E),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Expanded(
            child: Text(error, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    bool canStart,
    bool isConnected,
    bool isLoading,
    bool amIHost,
  ) {
    final playerCount = context.watch<GameProvider>().players.length;

    // ✅ FIX: Only enable start if WebSocket is connected AND we have players
    final canActuallyStart =
        canStart &&
        isConnected &&
        playerCount >= 3 && // Verify we have the player list
        !isLoading;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A0F2E).withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Connection status indicator
            if (!isConnected)
              Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Connecting to game server...',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ),

            // Player count indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFF2D1B4E).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFD4AF37).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, color: Color(0xFFD4AF37), size: 20),
                  SizedBox(width: 8),
                  Text(
                    '$playerCount / 8 Players',
                    style: TextStyle(
                      color: Color(0xFFC0C0D8),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (playerCount < 3) ...[
                    SizedBox(width: 8),
                    Text(
                      '(Need ${3 - playerCount} more)',
                      style: TextStyle(
                        color: Color(0xFFC0C0D8).withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                // Leave button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // ✅ Proper leave sequence
                      final gameProvider = context.read<GameProvider>();

                      // 1. Send WebSocket leave message
                      if (gameProvider.currentRoomId != null) {
                        gameProvider.leaveRoom(); // New method we'll create
                      }

                      // 2. Navigate back
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: Icon(Icons.exit_to_app),
                    label: Text('Leave Room'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2D1B4E),
                      foregroundColor: Color(0xFFC0C0D8),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Start button (only for host)
                if (amIHost)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: canActuallyStart
                          ? () async {
                              final gameProvider = context.read<GameProvider>();
                              final success = await gameProvider.startGame();

                              // ✅ FIX: Show user-friendly error if start fails
                              if (!success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      gameProvider.error?.contains(
                                                'WebSocket',
                                              ) ??
                                              false
                                          ? 'Please wait for all players to connect'
                                          : (gameProvider.error ??
                                                'Failed to start game'),
                                    ),
                                    backgroundColor: Color(0xFF8B0000),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          : null,
                      icon: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.play_arrow),
                      label: Text(
                        isLoading
                            ? 'Starting...'
                            : !isConnected
                            ? 'Connecting...'
                            : playerCount < 3
                            ? 'Need 3+ Players'
                            : 'Start Game',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canActuallyStart
                            ? Color(0xFFD4AF37)
                            : Color(0xFF2D1B4E),
                        foregroundColor: canActuallyStart
                            ? Color(0xFF1A0F2E)
                            : Color(0xFFC0C0D8).withValues(alpha: 0.5),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
