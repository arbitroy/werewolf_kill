import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../core/models/game_state.dart';
import '../providers/game_provider.dart';
import '../core/models/player.dart';
import '../widgets/game/countdown_timer.dart';
import '../widgets/game/hunter_revenge_dialog.dart';

class GameScreen extends StatefulWidget {
  final String roomId;

  const GameScreen({super.key, required this.roomId});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _phaseController;

  @override
  void initState() {
    super.initState();
    _phaseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);

      // Listen for hunter revenge prompt (private to hunter)
      gameProvider.addListener(() {
        if (gameProvider.amITheHunter &&
            gameProvider.hunterTargets.isNotEmpty &&
            mounted) {
          _showHunterRevengeDialog();
        }
      });
    });
  }

  void _showHunterRevengeDialog() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer<GameProvider>(
        builder: (context, provider, child) {
          return HunterRevengeDialog(
            availableTargets: provider.hunterTargets,
            secondsRemaining: provider.hunterRevengeSecondsRemaining,
            onTargetSelected: (targetId) {
              provider.submitHunterRevenge(targetId);
            },
          );
        },
      ),
    );
  }

  Widget _buildHunterRevengeOverlay() {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        if (!gameProvider.isHunterRevengeActive || gameProvider.amITheHunter) {
          return SizedBox.shrink();
        }

        return Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.8),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎯', style: TextStyle(fontSize: 80)),
                  SizedBox(height: 16),
                  Text(
                    'HUNTER\'S REVENGE',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'The Hunter is choosing their final target...',
                    style: TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFD4AF37), width: 2),
                    ),
                    child: Text(
                      '${gameProvider.hunterRevengeSecondsRemaining}s',
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final gameState = gameProvider.gameState;
        final players = gameProvider.players;
        final myPlayer = gameProvider.myPlayer;
        final selectedTargetId = gameProvider.selectedTargetId;

        final isNight = gameState?.isNightPhase ?? false;
        final isVoting = gameState?.isVotingPhase ?? false;
        final myRole = myPlayer?.role ?? 'VILLAGER';

        // ✅ DEBUG: Add logging
        print('🎮 Game Screen Build:');
        print('   - My Player: ${myPlayer?.username}');
        print('   - My Role: $myRole');
        print('   - Phase: ${gameState?.phase}');
        print('   - Is Night: $isNight');
        print('   - Is Voting: $isVoting');

        return Scaffold(
          body: AnimatedContainer(
            duration: Duration(seconds: 2),
            decoration: BoxDecoration(
              gradient: isNight ? _nightGradient : _dayGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(myRole, gameProvider),
                  SizedBox(height: 16),
                  _buildPhaseIndicator(gameState, isNight),
                  if (gameProvider.seerResult != null)
                    _buildSeerResult(gameProvider.seerResult!),
                  if (gameProvider.lastActionResult != null)
                    _buildActionResult(gameProvider.lastActionResult!),
                  SizedBox(height: 24),
                  Expanded(
                    child: _buildPlayerCircle(
                      players,
                      myPlayer?.id,
                      selectedTargetId,
                      gameProvider,
                    ),
                  ),
                  _buildActionPanel(gameProvider, myRole, isNight, isVoting),
                  _buildHunterRevengeOverlay(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(String myRole, GameProvider gameProvider) {
    final displayRoomId = widget.roomId.length > 8
        ? widget.roomId.substring(0, 8)
        : widget.roomId;

    // ✅ Show debug info if role is missing
    final roleText = myRole.isNotEmpty ? _getRoleText(myRole) : '❓ Loading...';
    final roleColor = myRole.isNotEmpty ? _getRoleColor(myRole) : Colors.grey;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFFC0C0D8)),
            onPressed: () {
              gameProvider.leaveRoom();
              Navigator.pop(context);
            },
          ),
          Column(
            children: [
              Text(
                'Room $displayRoomId',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 16,
                  color: Color(0xFFC0C0D8),
                ),
              ),
              Text(
                roleText,
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 12,
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildStaticPhaseIndicator(dynamic gameState, bool isNight) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNight ? Color(0xFFC0C0D8) : Color(0xFFFFE4B5),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNight ? Icons.nightlight_round : Icons.wb_sunny,
            color: isNight ? Color(0xFFC0C0D8) : Colors.orange,
            size: 28,
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isNight ? 'Night Phase' : 'Day Phase',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Color(0xFFC0C0D8) : Colors.white,
                ),
              ),
              Text(
                'Day ${gameState?.dayNumber ?? 0}',
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 14,
                  color: isNight
                      ? Color(0xFFC0C0D8).withOpacity(0.8)
                      : Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator(GameState? gameState, bool isNight) {
    if (gameState == null || gameState.phaseEndTime == null) {
      // Fallback for old format
      return _buildStaticPhaseIndicator(gameState, isNight);
    }

    return Column(
      children: [
        // Phase name
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isNight ? Color(0xFFC0C0D8) : Color(0xFFFFE4B5),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isNight ? Icons.nightlight_round : Icons.wb_sunny,
                color: isNight ? Color(0xFFC0C0D8) : Colors.orange,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                _getPhaseDisplayName(gameState.phase),
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Color(0xFFC0C0D8) : Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Day ${gameState.dayNumber}',
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 14,
                  color: (isNight ? Color(0xFFC0C0D8) : Colors.white)
                      .withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        // ✅ COUNTDOWN TIMER
        CountdownTimer(
          endTimeMs: gameState.phaseEndTime!,
          isNight: isNight,
          onComplete: () {
            print('⏰ Phase timer completed on client side');
            // Phase should auto-transition from backend
          },
        ),
      ],
    );
  }

  String _getPhaseDisplayName(String phase) {
    switch (phase.toUpperCase()) {
      case 'NIGHT':
        return 'Night Phase';
      case 'DAY':
        return 'Discussion';
      case 'VOTING':
        return 'Voting Time';
      case 'STARTING':
        return 'Game Starting...';
      default:
        return phase;
    }
  }

  Widget _buildSeerResult(String result) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFD4AF37).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFD4AF37)),
      ),
      child: Row(
        children: [
          Icon(Icons.wb_incandescent, color: Color(0xFFD4AF37)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              result,
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionResult(String result) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF2E7D32).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF2E7D32)),
      ),
      child: Text(
        result,
        style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPlayerCircle(
    List<Player> players,
    String? myId,
    String? selectedTargetId,
    GameProvider gameProvider,
  ) {
    if (players.isEmpty) {
      return Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final radius =
            math.min(constraints.maxWidth, constraints.maxHeight) * 0.35;
        return Stack(
          children: List.generate(players.length, (index) {
            final angle = (2 * math.pi / players.length) * index - math.pi / 2;
            final x = radius * math.cos(angle);
            final y = radius * math.sin(angle);
            final player = players[index];
            final isMe = player.id == myId;
            final isSelected = player.id == selectedTargetId;

            return Positioned(
              left: constraints.maxWidth / 2 + x - 40,
              top: constraints.maxHeight / 2 + y - 40,
              child: _buildPlayerAvatar(player, isMe, isSelected, gameProvider),
            );
          }),
        );
      },
    );
  }

  Widget _buildPlayerAvatar(
    Player player,
    bool isMe,
    bool isSelected,
    GameProvider gameProvider,
  ) {
    final canSelect = gameProvider.canTarget(player.id);

    return GestureDetector(
      onTap: canSelect ? () => gameProvider.selectTarget(player.id) : null,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? Color(0xFF8B0000)
              : isMe
              ? Color(0xFFD4AF37)
              : player.isAlive
              ? Color(0xFF2E7D32)
              : Color(0xFF424242),
          border: Border.all(
            color: isSelected
                ? Colors.red
                : isMe
                ? Color(0xFFD4AF37)
                : Colors.white,
            width: isSelected ? 4 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              player.username[0].toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              player.username,
              style: TextStyle(fontSize: 10, color: Colors.white),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!player.isAlive)
              Icon(Icons.close, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPanel(
    GameProvider gameProvider,
    String myRole,
    bool isNight,
    bool isVoting,
  ) {
    // ✅ Add defensive check
    if (myRole.isEmpty || myRole == 'VILLAGER' || myRole == 'HUNTER') {
      if (isNight) {
        print('🌙 Non-acting role at night: $myRole');
        return _buildWaitingPanel();
      }
    }

    // ✅ Add more explicit role checks for night actions
    if (isNight) {
      final roleUpper = myRole.toUpperCase();
      print('🌙 Night phase - checking role: $roleUpper');

      if (roleUpper == 'WEREWOLF' ||
          roleUpper == 'SEER' ||
          roleUpper == 'DOCTOR') {
        return _buildNightActionPanel(gameProvider, myRole);
      } else {
        print('⏸️ Role $roleUpper waits at night');
        return _buildWaitingPanel();
      }
    } else if (isVoting) {
      return _buildVotePanel(gameProvider);
    }

    return _buildWaitingPanel();
  }

  Widget _buildWaitingPanel() {
    return Container(
      height: 80,
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
      child: Center(
        child: Text(
          'Waiting for others...',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 16,
            color: Color(0xFFC0C0D8),
          ),
        ),
      ),
    );
  }

  Widget _buildVotePanel(GameProvider gameProvider) {
    final buttonText = gameProvider.getActionButtonText();
    final canSubmit = gameProvider.canSubmitAction();

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
            gameProvider.hasVoted
                ? 'Vote cast! Waiting for others...'
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
              onPressed: canSubmit
                  ? () {
                      if (gameProvider.selectedTargetId != null) {
                        gameProvider.submitVote(gameProvider.selectedTargetId!);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B0000),
                disabledBackgroundColor: Colors.grey,
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNightActionPanel(GameProvider gameProvider, String myRole) {
    final buttonText = gameProvider.getActionButtonText();
    final canSubmit = gameProvider.canSubmitAction();

    String actionIcon;
    String actionText;

    print('🌙 Building night action panel for role: $myRole');

    switch (myRole.toUpperCase()) {
      case 'WEREWOLF':
        actionIcon = '🐺';
        actionText = gameProvider.hasActedTonight
            ? 'Attack submitted! Waiting...'
            : 'Choose your target';
        break;
      case 'SEER':
        actionIcon = '🔮';
        actionText = gameProvider.hasActedTonight
            ? 'Investigation complete!'
            : 'Choose player to investigate';
        break;
      case 'DOCTOR':
        actionIcon = '💊';
        actionText = gameProvider.hasActedTonight
            ? 'Protection applied!'
            : 'Choose player to protect';
        break;
      default:
        print('⚠️ Unexpected role in night action panel: $myRole');
        return _buildWaitingPanel();
    }

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
            '$actionIcon $actionText',
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
              onPressed: canSubmit
                  ? () {
                      if (gameProvider.selectedTargetId != null) {
                        gameProvider.submitNightAction(
                          gameProvider.selectedTargetId!,
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getRoleColor(myRole),
                disabledBackgroundColor: Colors.grey,
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleText(String role) {
    switch (role.toUpperCase()) {
      case 'WEREWOLF':
        return '🐺 Werewolf';
      case 'SEER':
        return '🔮 Seer';
      case 'DOCTOR':
        return '💊 Doctor';
      case 'HUNTER':
        return '🎯 Hunter';
      default:
        return '👤 Villager';
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'WEREWOLF':
        return Color(0xFF8B0000);
      case 'SEER':
        return Color(0xFFD4AF37);
      case 'DOCTOR':
        return Color(0xFF2E7D32);
      case 'HUNTER':
        return Color(0xFFFF6B35);
      default:
        return Color(0xFF4A5568);
    }
  }

  LinearGradient get _nightGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F0A1E), Color(0xFF2D1B4E), Color(0xFF1A0F2E)],
  );

  LinearGradient get _dayGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF87CEEB), Color(0xFFFFE4B5), Color(0xFFFFDAB9)],
  );

  @override
  void dispose() {
    _phaseController.dispose();
    super.dispose();
  }
}
