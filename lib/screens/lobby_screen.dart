import 'package:flutter/material.dart';

class LobbyScreen extends StatefulWidget {
  final String userId;
  final String username;

  const LobbyScreen({super.key, required this.userId, required this.username});

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> with SingleTickerProviderStateMixin {
  late AnimationController _starController;
  List<Room> availableRooms = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    // TODO: Call API to get rooms
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      availableRooms = _mockRooms();
      isLoading = false;
    });
  }

  List<Room> _mockRooms() {
    return [
      Room(
        id: '1',
        name: 'Midnight Hunters',
        hostName: 'Alice',
        currentPlayers: 4,
        maxPlayers: 8,
        status: 'WAITING',
      ),
      Room(
        id: '2',
        name: 'Full Moon Party',
        hostName: 'Bob',
        currentPlayers: 6,
        maxPlayers: 8,
        status: 'WAITING',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
                child: Icon(
                  Icons.person,
                  size: 24,
                  color: Color(0xFFC0C0D8),
                ),
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
      child: Column(
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
                  onPressed: _loadRooms,
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFD4AF37),
                    ),
                  )
                : availableRooms.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: availableRooms.length,
                        itemBuilder: (context, index) {
                          return _buildRoomCard(availableRooms[index]);
                        },
                      ),
          ),
        ],
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

  Widget _buildRoomCard(Room room) {
    final isFull = room.currentPlayers >= room.maxPlayers;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isFull ? null : () => _joinRoom(room),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0xFF2D1B4E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFFD4AF37),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.nightlight_round,
                  color: Color(0xFFC0C0D8),
                  size: 30,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC0C0D8),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Host: ${room.hostName}',
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 14,
                        color: Color(0xFFC0C0D8).withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: Color(0xFFD4AF37),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${room.currentPlayers}/${room.maxPlayers}',
                          style: TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 14,
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                isFull ? Icons.lock : Icons.arrow_forward_ios,
                color: isFull 
                  ? Color(0xFF424242) 
                  : Color(0xFFD4AF37),
              ),
            ],
          ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Create New Room',
          style: TextStyle(
            fontFamily: 'Cinzel',
            color: Color(0xFFC0C0D8),
          ),
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
                  borderSide: BorderSide(
                    color: Color(0xFFD4AF37),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
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
              if (nameController.text.isNotEmpty) {
                _createRoom(nameController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E7D32),
            ),
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createRoom(String roomName) async {
    // TODO: Call API to create room
    print('Creating room: $roomName');
    // Navigate to waiting room
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => WaitingRoomScreen(roomId: newRoomId)
    // ));
  }

  void _joinRoom(Room room) async {
    // TODO: Call API to join room
    print('Joining room: ${room.name}');
    // Navigate to waiting room
  }

  void _quickMatch() {
    // TODO: Find and join first available room
    if (availableRooms.isNotEmpty) {
      _joinRoom(availableRooms.first);
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

class Room {
  final String id;
  final String name;
  final String hostName;
  final int currentPlayers;
  final int maxPlayers;
  final String status;

  Room({
    required this.id,
    required this.name,
    required this.hostName,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.status,
  });
}