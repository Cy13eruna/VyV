# Triangular System V&V - Modular Architecture

## 📁 Project Structure

```
SKETCH/
├── src/                    # Organized source code
│   ├── core/              # Core systems
│   │   ├── hex_grid.gd    # Hexagonal grid system (coordinator)
│   │   ├── hex_math.gd    # Hexagonal mathematics
│   │   ├── hex_point_generator.gd # Point generator
│   │   ├── hex_connection_generator.gd # Connection generator
│   │   ├── terrain_generator.gd # Terrain generator
│   │   ├── name_generator.gd # Name generator
│   │   └── game_state.gd  # Central game state (coordinator)
│   ├── data/              # Data structures
│   │   ├── game_enums.gd  # Game enumerations
│   │   ├── hex_point.gd   # Hexagonal point
│   │   ├── terrain_connection.gd # Terrain connection
│   │   ├── game_unit.gd   # Game unit
│   │   └── domain.gd      # Domain
│   ├── game/              # Game logic
│   │   ├── game_controller.gd # Main controller
│   │   ├── game_renderer.gd   # Rendering system (coordinator)
│   │   ├── movement_system.gd # Movement system
│   │   ├── visibility_system.gd # Visibility system
│   │   ├── turn_system.gd # Turn system
│   │   ├── connection_renderer.gd # Connection rendering
│   │   ├── point_renderer.gd # Point rendering
│   │   └── domain_renderer.gd # Domain rendering
│   └── ui/                # User interface
│       └── game_ui.gd     # Game UI
├── scenes/                # Godot scenes
│   ├── main_game.tscn     # Main scene
│   └── main_game.gd       # Main scene script
└── README.md              # This documentation
```

## 🎯 Main Components

### Core
- **HexGrid**: Hexagonal grid coordinator
- **HexMath**: Hexagonal mathematical utilities
- **HexPointGenerator**: Hexagonal point generation
- **HexConnectionGenerator**: Point connection generation
- **TerrainGenerator**: Random terrain generation
- **NameGenerator**: Name generation for units and domains
- **GameState**: Central game state coordinator

### Data
- **GameEnums**: All enumerations (EdgeType, PlayerID, etc.)
- **HexPoint**: Represents a point in the hexagonal grid
- **TerrainConnection**: Connection between points with terrain type
- **GameUnit**: Player unit
- **Domain**: Player domain

### Game
- **GameController**: Main controller, coordinates all systems
- **GameRenderer**: Rendering system coordinator
- **MovementSystem**: Unit movement logic
- **VisibilitySystem**: Fog of war and visibility system
- **TurnSystem**: Turn and round management
- **ConnectionRenderer**: Hexagonal connection rendering
- **PointRenderer**: Hexagonal point rendering
- **DomainRenderer**: Hexagonal domain rendering

### UI
- **GameUI**: User interface (buttons, labels, etc.)

## 🔄 Execution Flow

1. **MainGame** (main scene) creates the **GameController**
2. **GameController** initializes:
   - **GameState** (game state)
   - **GameRenderer** (rendering)
   - **GameUI** (interface)
3. **GameState** generates the hexagonal grid via **HexGrid**
4. **GameRenderer** draws the game based on **GameState**
5. **GameUI** shows information and receives user input

## 🎮 Preserved Features

- ✅ Hexagonal grid with 37 points (radius 3)
- ✅ Terrain system (Field, Forest, Mountain, Water)
- ✅ Units with movement and actions
- ✅ Domains with power system
- ✅ Fog of war
- ✅ Turn system
- ✅ Forced revelation in forests
- ✅ Interface with buttons and information

## 🔧 Refactoring Benefits

- **Modularity**: Each component has specific responsibility
- **Maintainability**: Organized and easy-to-find code
- **Extensibility**: Easy to add new features
- **Testability**: Components can be tested in isolation
- **Reusability**: Classes can be reused in other contexts
- **Multiplayer Preparation**: Structure ready for expansion

## 📋 Next Steps

The architecture is ready for:
- Multiplayer implementation
- Addition of new mechanics
- Save/load system
- Different unit types
- Variable-sized maps
- Domain upgrade system