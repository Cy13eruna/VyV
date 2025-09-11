# HexStrategy

Strategic hexagonal board game with multiplayer support built in Godot 4 with C#.

## Game Structure

### Core Entities

- **Board**: White background game area containing the hexagonal grid
- **Nodes**: Black points arranged in hexagonal pattern - movement destinations
- **Units**: Colored pieces (player-dependent) that move between nodes
- **Paths**: Light gray connections between adjacent nodes - control movement
- **Domains**: Hexagonal territories (1 center + 6 adjacent nodes + 12 paths) - player-colored
- **Players**: Users controlling units and domains - each with unique color

### Architecture

```
HexStrategy/
├── Client/           # Godot 4 + C# client
│   ├── Scripts/      # Game logic scripts
│   └── Scenes/       # Godot scene files
├── Server/           # Go + Fiber backend (future)
├── Shared/           # Common game entities
└── project.godot    # Godot project configuration
```

### Technology Stack

- **Client**: Godot 4 + C# + Godot.NET
- **Server**: Go + Fiber + NATS (planned)
- **Database**: PostgreSQL + Redis + TimescaleDB (planned)
- **Deploy**: Railway/Fly.io → Kubernetes (planned)

## Getting Started

1. Open project in Godot 4.4+
2. Ensure .NET 8.0 is installed
3. Build project (Project → Tools → C# → Build Solution)
4. Run scene (F5)

## Controls

- **Click unit**: Select your unit
- **Click adjacent node**: Move selected unit
- **Turn-based**: Alternates between players

## Current Features

- Hexagonal grid generation
- Basic unit movement
- Turn-based gameplay
- Visual representation of all entities
- Domain system foundation

## Planned Features

- Multiplayer networking
- Domain control mechanics
- Advanced unit types
- Strategic objectives
- Real-time synchronization