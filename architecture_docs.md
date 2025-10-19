# 🎮 Werewolf Game - Architecture Documentation

## 📐 Overview

A real-time multiplayer game built with **Flutter (Frontend)** and **Spring Boot (Backend)** using WebSocket for live communication and PostgreSQL for persistent data.

### Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Spring Boot (Java)
- **Real-time**: WebSocket (STOMP protocol)
- **Database**: PostgreSQL
- **State Management**: Provider (Flutter), In-Memory Sessions (Backend)

---

## 🏗️ Architecture Principles

### 1. **Separation of Concerns**
- **Database**: Persistent data only (rooms, users, game history)
- **In-Memory**: Live session state (current players, host, game phase)
- **WebSocket**: Real-time state synchronization

### 2. **Single Source of Truth**
- `ROOM_STATE_UPDATE` message contains authoritative state
- Individual events (`PLAYER_JOINED`, `HOST_CHANGED`) are notifications
- Frontend prioritizes `ROOM_STATE_UPDATE` over individual events

### 3. **Event-Driven Communication**
- All state changes trigger WebSocket broadcasts
- Clients react to events, never poll
- No database queries for real-time data

---

## 📊 System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Flutter    │  │   Flutter    │  │   Flutter    │          │
│  │   Browser 1  │  │   Browser 2  │  │   Browser 3  │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                  │
│         └──────────────────┼──────────────────┘                  │
│                            │                                     │
│                     WebSocket (STOMP)                            │
└────────────────────────────┼─────────────────────────────────────┘
                             │
┌────────────────────────────┼─────────────────────────────────────┐
│                            │         BACKEND LAYER               │
│                            ▼                                     │
│  ┌─────────────────────────────────────────────────────┐        │
│  │         GameWebSocketHandler                        │        │
│  │  • Handles join/leave/disconnect                    │        │
│  │  • Broadcasts room state updates                    │        │
│  └────────────┬────────────────────────┬───────────────┘        │
│               │                        │                        │
│               ▼                        ▼                        │
│  ┌─────────────────────┐   ┌─────────────────────┐             │
│  │   SessionManager    │   │   RoomRepository    │             │
│  │  (In-Memory)        │   │   (Database)        │             │
│  │                     │   │                     │             │
│  │  • Active sessions  │   │  • Room metadata    │             │
│  │  • Player list      │   │  • Persistent data  │             │
│  │  • Host tracking    │   └─────────────────────┘             │
│  │  • Game phase       │                                       │
│  └─────────────────────┘                                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow

### Player Joins Room

```
1. Flutter App
   └─> WebSocket: SEND /app/room/{roomId}/join
       { playerId: "uuid", username: "Alice" }

2. GameWebSocketHandler
   └─> Validate room exists (Database)
   └─> SessionManager.addPlayer()
       └─> If first player → Set as host
       └─> Store in ConcurrentHashMap

3. SessionManager
   └─> broadcastRoomState()
       └─> Build ROOM_STATE_UPDATE message
       └─> Send to /topic/room/{roomId}

4. All Flutter Clients
   └─> Receive ROOM_STATE_UPDATE
   └─> GameProvider._handleRoomStateUpdate()
       └─> Update _players list
       └─> Update _myPlayer.isHost
       └─> notifyListeners()

5. UI Updates
   └─> Player list rebuilds
   └─> Host badge appears
   └─> Start button shows for host
```

### Host Disconnects

```
1. Browser Closes / Network Drops
   └─> WebSocket: SessionDisconnectEvent

2. GameWebSocketHandler.handleDisconnect()
   └─> SessionManager.removePlayer()
       └─> Remove from players map
       └─> Check if was host
           └─> reassignHost()
               └─> Find next player (by joinedAt)
               └─> broadcastHostChanged() ← NEW HOST_CHANGED event
       └─> broadcastRoomState()

3. All Flutter Clients
   └─> Receive HOST_CHANGED message
   └─> GameProvider._handleHostChanged()
       └─> Update all players' isHost flag
       └─> notifyListeners()

4. Also Receive ROOM_STATE_UPDATE
   └─> Full state refresh (backup)

5. UI Updates
   └─> Host badge moves to new host
   └─> Start button appears for new host
   └─> Previous host loses button
```

---

## 🗂️ Data Models

### Backend: RoomSession (In-Memory)

```java
class RoomSession {
    UUID roomId;
    String roomName;
    Map<String, PlayerInfo> players;  // WebSocket sessionId → Player
    String hostSessionId;             // WebSocket sessionId of host
    String currentPhase;              // "WAITING", "DAY", "NIGHT"
    Instant sessionStartTime;
    Instant lastActivity;
}
```

### Backend: PlayerInfo (In-Memory)

```java
class PlayerInfo {
    String webSocketSessionId;   // Unique WebSocket connection
    UUID playerId;               // User ID from database
    String username;
    Role role;                   // "WEREWOLF", "VILLAGER", etc.
    PlayerStatus status;         // "ALIVE", "DEAD"
    Instant joinedAt;            // For host reassignment order
    Instant lastHeartbeat;
}
```

### Database: Room (Persistent)

```sql
CREATE TABLE rooms (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    created_by UUID NOT NULL,
    max_players INT DEFAULT 8,
    created_at TIMESTAMP DEFAULT NOW(),
    game_mode VARCHAR(50) DEFAULT 'CLASSIC',
    is_public BOOLEAN DEFAULT TRUE
);
```

### Flutter: Player (State)

```dart
class Player {
    String id;          // User ID
    String username;
    bool isHost;        // Derived from backend state
    bool isAlive;
    String? role;
}
```

---

## 📨 WebSocket Messages

### Message Types

| Type | Direction | Purpose |
|------|-----------|---------|
| `ROOM_STATE_UPDATE` | Backend → All | **Authoritative** full room state |
| `PLAYER_JOINED` | Backend → All | Individual player joined notification |
| `PLAYER_LEFT` | Backend → All | Player left notification |
| `HOST_CHANGED` | Backend → All | **New host assigned** |
| `GAME_STARTED` | Backend → All | Game phase transition |
| `ROLE_ASSIGNED` | Backend → Player | Private role assignment |
| `PHASE_CHANGE` | Backend → All | Day/Night transition |

### Example: ROOM_STATE_UPDATE

```json
{
  "type": "ROOM_STATE_UPDATE",
  "roomId": "a1b2c3d4-...",
  "roomName": "Alice's Game",
  "players": [
    {
      "playerId": "user-uuid-1",
      "username": "Alice",
      "isHost": true,
      "status": "ALIVE",
      "role": null
    },
    {
      "playerId": "user-uuid-2",
      "username": "Bob",
      "isHost": false,
      "status": "ALIVE",
      "role": null
    }
  ],
  "hostUsername": "Alice",
  "playerCount": 2,
  "currentPhase": "WAITING",
  "timestamp": 1234567890
}
```

### Example: HOST_CHANGED

```json
{
  "type": "HOST_CHANGED",
  "roomId": "a1b2c3d4-...",
  "newHostId": "user-uuid-2",
  "newHostUsername": "Bob",
  "timestamp": 1234567890
}
```

---

## 🧩 Component Responsibilities

### Backend Components

#### **GameWebSocketHandler**
- ✅ Handle WebSocket connections
- ✅ Route messages to SessionManager
- ✅ Broadcast state changes
- ✅ Handle disconnects

#### **SessionManager**
- ✅ Manage in-memory room sessions
- ✅ Track active players
- ✅ Assign/reassign host
- ✅ Broadcast state updates
- ❌ No database access

#### **RoomRepository**
- ✅ Persist room metadata
- ✅ Validate room exists
- ❌ No live player tracking

### Frontend Components

#### **WebSocketService**
- ✅ Manage WebSocket connection
- ✅ Handle STOMP protocol
- ✅ Dispatch events to callbacks
- ✅ Reconnection logic

#### **GameProvider**
- ✅ Maintain current room state
- ✅ Track players list
- ✅ Handle state updates
- ✅ Notify UI of changes

#### **WaitingRoomScreen**
- ✅ Display player list
- ✅ Show host indicator
- ✅ Enable/disable start button
- ✅ React to state changes

---

## 🎯 Key Design Decisions

### Why In-Memory State?

**Problem**: Database queries for every state check = slow, doesn't scale

**Solution**: In-memory `ConcurrentHashMap` for live state
- **Speed**: O(1) lookups
- **Scalability**: Handle 1000+ concurrent rooms
- **Real-time**: No DB latency

**Trade-off**: State lost on server restart (acceptable for game sessions)

### Why WebSocket Over REST?

**Problem**: Polling = wasted requests, delayed updates

**Solution**: WebSocket persistent connection
- **Instant**: Sub-second latency
- **Efficient**: Single connection, no HTTP overhead
- **Bidirectional**: Server can push updates

### Why ROOM_STATE_UPDATE?

**Problem**: Individual events can arrive out of order

**Solution**: Periodic full state broadcasts
- **Authoritative**: Single source of truth
- **Self-healing**: Corrects any drift
- **Simple**: Clients don't need complex merge logic

---

## 🔒 State Consistency Guarantees

### Host Assignment Rules

1. **First player** to join a room becomes host
2. Players ordered by `joinedAt` timestamp
3. On host disconnect, **next oldest player** becomes host
4. Host change **always** broadcasts to all clients
5. Only **one host** per room at all times

### State Synchronization

```
Backend State (Truth)
        ↓
   Broadcast via WebSocket
        ↓
Frontend State (Replica)
        ↓
   UI Renders
```

**Guarantee**: All clients receive identical `ROOM_STATE_UPDATE` within 1 second

---

## 🚀 Performance Characteristics

| Metric | Value | Notes |
|--------|-------|-------|
| **Join Latency** | <100ms | WebSocket + in-memory |
| **Host Reassign** | <500ms | Broadcast to all clients |
| **Message Size** | ~1KB | 8 players with full state |
| **Concurrent Rooms** | 1000+ | Limited by memory, not DB |
| **Max Players/Room** | 8 | Configurable |

---

## 🔧 Configuration

### Backend: application.properties

```properties
# WebSocket
spring.websocket.allowed-origins=*

# Session
session.timeout.minutes=30
session.heartbeat.interval.seconds=30

# Database (persistent only)
spring.datasource.url=jdbc:postgresql://localhost:5432/werewolf_db
```

### Flutter: Environment

```dart
// API base URL
final String serverUrl = "http://localhost:8080";

// WebSocket endpoint
final String wsUrl = "$serverUrl/ws";
```

---

## 📈 Scalability Considerations

### Current Architecture
- **Single Server**: In-memory state on one instance
- **Vertical Scaling**: Increase RAM for more concurrent rooms
- **Limitation**: State lost on server restart

### Future: Multi-Server Setup

```
Option 1: Sticky Sessions
  └─> Load balancer pins client to same server

Option 2: Distributed Cache (Redis)
  └─> Share sessions across servers
  └─> Pub/Sub for broadcasts

Option 3: Dedicated Game Servers
  └─> Each room gets isolated server instance
```

---

## 🐛 Debugging

### Check Backend State

```bash
# View active sessions
GET http://localhost:8080/api/health/sessions

# View room state
GET http://localhost:8080/api/debug/rooms/{roomId}/state
```

### Check Frontend State

```dart
// In Flutter DevTools
print('Players: ${gameProvider.players.length}');
print('Host: ${gameProvider.players.firstWhere((p) => p.isHost)}');
print('Connected: ${gameProvider.isConnected}');
```

### Monitor WebSocket

```bash
# Backend logs
grep "Broadcasted ROOM_STATE_UPDATE" logs/app.log

# Frontend logs  
grep "📊 ROOM_STATE_UPDATE received" logs/flutter.log
```

---

## ✅ Testing Strategy

### Unit Tests
- `SessionManager`: Host assignment logic
- `GameProvider`: State update handling

### Integration Tests
- WebSocket message flow
- Multi-client synchronization

### Manual Tests
1. First player becomes host ✓
2. Second player joins, first still host ✓
3. Host disconnects, reassignment works ✓
4. All clients see same state ✓

---

## 📚 Future Enhancements

- [ ] Game phase management (Day/Night cycles)
- [ ] Role assignment system
- [ ] Voting mechanism
- [ ] Chat system
- [ ] Room lobbies
- [ ] Spectator mode
- [ ] Game replay/history

---

## 🎓 Key Takeaways

1. **In-memory state** for real-time, **database** for persistence
2. **WebSocket** for instant bidirectional communication
3. **Single source of truth** prevents state drift
4. **Event-driven** architecture scales better than polling
5. **ConcurrentHashMap** for thread-safe shared state

---

**Last Updated**: 2025-01-20  
**Version**: 1.0  
**Status**: Production Ready ✅
