import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../providers/auth_provider.dart';
import '../core/models/room.dart';

class LobbyScreen extends StatefulWidget {
  final String userId;
  final String username;

  const LobbyScreen({super.key, required this.userId, required this.username});

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _starController;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Load rooms when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set token on RoomProvider from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);

      if (authProvider.token != null) {
        roomProvider.setToken(authProvider.token!);
      }

      _loadRooms();
    });
  }

  Future<void> _loadRooms() async {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    await roomProvider.loadRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0A1E), Color(0xFF2D1B4E), Color(0xFF1A0F2E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 24),
              _buildQuickActions(),
              SizedBox(height: 24),
              _buildRoomsList(),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 14,
                  color: Color(0xFFC0C0D8).withOpacity(0.7),
                ),
              ),
              Text(
                widget.username,
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC0C0D8),
                ),
              ),
            ],
          ),
          Stack(
            children: [
              AnimatedBuilder(
                animation: _starController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _starController.value * 6.28,
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: Color(0xFFD4AF37).withOpacity(0.3),
                    ),
                  );
                },
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Icon(Icons.person, size: 24, color: Color(0xFFC0C0D8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Create Room',
              Icons.add_circle_outline,
              Color(0xFF2E7D32),
              () => _showCreateRoomDialog(),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              'Quick Match',
              Icons.flash_on,
              Color(0xFFD4AF37),
              () => _quickMatch(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 100,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsList() {
    return Expanded(
      child: Consumer<RoomProvider>(
        builder: (context, roomProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Rooms',
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC0C0D8),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Color(0xFFD4AF37)),
                      onPressed: roomProvider.isLoading ? null : _loadRooms,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),

              // Error message
              if (roomProvider.error != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            roomProvider.error!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 12),

              Expanded(
                child: roomProvider.isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFFD4AF37)),
                            SizedBox(height: 16),
                            Text(
                              'Loading rooms...',
                              style: TextStyle(
                                color: Color(0xFFC0C0D8).withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : roomProvider.rooms.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: roomProvider.rooms.length,
                        itemBuilder: (context, index) {
                          return _buildRoomCard(roomProvider.rooms[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.nightlight_round,
            size: 80,
            color: Color(0xFFC0C0D8).withOpacity(0.3),
          ),
          SizedBox(height: 16),
          Text(
            'No rooms available',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 18,
              color: Color(0xFFC0C0D8).withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create one to get started!',
            style: TextStyle(
              fontFamily: 'Lora',
              fontSize: 14,
              color: Color(0xFFC0C0D8).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // In _buildRoomCard method
  Widget _buildRoomCard(Room room) {
    // ✅ Check if game is active
    final isGameActive = room.status != null && room.status != 'WAITING';
    final canJoin = !isGameActive && room.currentPlayers < room.maxPlayers;

    return Card(
      color: Color(0xFF2D1B4E),
      child: ListTile(
        leading: Icon(
          Icons.people,
          color: isGameActive ? Colors.red : Color(0xFFD4AF37),
        ),
        title: Text(
          room.name,
          style: TextStyle(fontFamily: 'Cinzel', color: Color(0xFFC0C0D8)),
        ),
        subtitle: Text(
          isGameActive
              ? '🎮 Game in Progress'
              : '${room.currentPlayers}/${room.maxPlayers} players',
          style: TextStyle(
            color: isGameActive
                ? Colors.red
                : Color(0xFFC0C0D8).withOpacity(0.7),
          ),
        ),
        trailing: ElevatedButton(
          onPressed: canJoin ? () => _joinRoom(room) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canJoin ? Color(0xFF2E7D32) : Colors.grey,
          ),
          child: Text(isGameActive ? 'In Progress' : 'Join'),
        ),
      ),
    );
  }

  void _showCreateRoomDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A0F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Create New Room',
          style: TextStyle(fontFamily: 'Cinzel', color: Color(0xFFC0C0D8)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: Color(0xFFC0C0D8)),
              decoration: InputDecoration(
                labelText: 'Room Name',
                labelStyle: TextStyle(
                  fontFamily: 'Lora',
                  color: Color(0xFFC0C0D8).withOpacity(0.7),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Color(0xFFC0C0D8).withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Color(0xFFC0C0D8))),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                _createRoom(nameController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2E7D32)),
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createRoom(String roomName) async {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    print('🔵 Creating room: $roomName');

    final room = await roomProvider.createRoom(
      roomName,
      authProvider.currentUser!.id,
    );

    if (room != null && mounted) {
      print('✅ Room created: ${room.id}');
      // Navigate to waiting room
      Navigator.pushNamed(
        context,
        '/waiting',
        arguments: {'roomId': room.id, 'roomName': room.name, 'isHost': true},
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(roomProvider.error ?? 'Failed to create room'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );
    }
  }

  void _joinRoom(Room room) async {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    print('🔵 Joining room: ${room.name}');

    final success = await roomProvider.joinRoom(
      room.id,
      authProvider.currentUser!.id,
      authProvider.currentUser!.username,
    );

    if (success && mounted) {
      print('✅ Joined room: ${room.id}');
      // Navigate to waiting room
      Navigator.pushNamed(
        context,
        '/waiting',
        arguments: {'roomId': room.id, 'roomName': room.name, 'isHost': false},
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(roomProvider.error ?? 'Failed to join room'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );
    }
  }

  void _quickMatch() {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);

    if (roomProvider.rooms.isNotEmpty) {
      // Find first room that's not full
      final availableRoom = roomProvider.rooms.firstWhere(
        (room) => room.currentPlayers < room.maxPlayers,
        orElse: () => roomProvider.rooms.first,
      );

      _joinRoom(availableRoom);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No rooms available for quick match'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );
    }
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }
}
