# 🛡️ ARCA DE NOÉ - V&V GAME RECONSTRUCTION BLUEPRINT

## 📋 QODO ASSISTANT INSTRUCTIONS

### 🎯 PRIMARY OBJECTIVE
Rebuild the V&V (Vagabonds & Valleys) game from scratch using extreme modular ONION architecture.

### 🚨 CRITICAL CONTEXT
- **CURRENT PROBLEM**: 73KB monolithic main_game.gd file
- **FAILED ATTEMPTS**: 5 previous modularization attempts failed
- **SOLUTION**: Complete rebuild with modular architecture from day 1
- **TIMELINE**: Original game built in 2 days, reconstruction should be fast

### ⚡ CORE PRINCIPLES (MANDATORY)
1. **ZERO MONOLITHS**: No file > 200 lines
2. **ONE FUNCTION = ONE FILE**: Maximum granularity
3. **ONION ARCHITECTURE**: Dependencies always point inward
4. **MULTIPLAYER-FIRST**: Design for networking from start

---

## 📊 CURRENT GAME STATE ANALYSIS

### ✅ IMPLEMENTED FEATURES
```
GRID_SYSTEM:
- Hexagonal grid: 37 points, axial coordinates (q,r)
- 60° rotation applied
- Corner detection (6 points with 3 edges)

UNIT_SYSTEM:
- 2 units with movement, actions, collision
- Turn-based: 1 action per turn
- Emoji representation: 🚶🏻‍♀️

DOMAIN_SYSTEM:
- Hexagonal domains at spawn points
- Power economy: 1 generated/turn, 1 consumed/action
- Unique names with matching initials

FOG_OF_WAR:
- Terrain-based visibility
- Toggle with SPACE key
- Domain permanent revelation

TURN_SYSTEM:
- Player alternation
- Action restoration
- Power generation
- Skip turn functionality

TERRAIN_SYSTEM:
- 4 types: FIELD(50%), FOREST/WATER/MOUNTAIN(16.7% each)
- Movement/visibility rules per type

UI_SYSTEM:
- Hover detection with magenta preview
- Click-to-move
- Action/player labels
- FPS display
```

### 🚀 PLANNED FUTURE FEATURES
```
TECH_TREE:
- Permission-based unlocks
- Research progression
- Special abilities/powers

STRUCTURES:
- Buildable on paths within domains
- Multiple types (defense, economy)
- Construction costs/time

COMPLEX_INTERACTIONS:
- Inter-domain interactions
- Inter-unit interactions
- Unit-domain interactions

DYNAMIC_SCALING:
- Map size based on player count
- N players, N units, N domains

MULTIPLAYER:
- Online system with matchmaking
- Client-server architecture
```

---

## 🏗️ MODULAR ARCHITECTURE SPECIFICATION

### 📁 FOLDER STRUCTURE
```
SKETCH/
├── core/                    # CORE LAYER
│   ├── entities/           # Business entities
│   │   ├── hex_point.gd
│   │   ├── hex_edge.gd
│   │   ├── unit.gd
│   │   ├── domain.gd
│   │   ├── terrain.gd
│   │   ├── player.gd
│   │   ├── technology.gd
│   │   ├── structure.gd
│   │   └── interaction.gd
│   └── value_objects/      # Immutable data objects
│       ├── hex_coordinate.gd
│       ├── position.gd
│       ├── game_constants.gd
│       ├── tech_node.gd
│       └── permission.gd
│
├── application/            # APPLICATION LAYER
│   ├── services/          # Business logic services
│   │   ├── grid_service.gd
│   │   ├── movement_service.gd
│   │   ├── visibility_service.gd
│   │   ├── turn_service.gd
│   │   ├── domain_service.gd
│   │   ├── tech_tree_service.gd
│   │   └── structure_service.gd
│   └── use_cases/         # Application workflows
│       ├── move_unit.gd
│       ├── skip_turn.gd
│       ├── toggle_fog.gd
│       ├── research_technology.gd
│       └── build_structure.gd
│
├── infrastructure/        # INFRASTRUCTURE LAYER
│   ├── input/            # Input handling
│   │   ├── mouse_handler.gd
│   │   ├── keyboard_handler.gd
│   │   └── input_manager.gd
│   ├── rendering/        # Visual rendering
│   │   ├── grid_renderer.gd
│   │   ├── unit_renderer.gd
│   │   ├── domain_renderer.gd
│   │   └── ui_renderer.gd
│   ├── networking/       # Network communication
│   │   ├── game_server.gd
│   │   ├── client_connection.gd
│   │   └── network_manager.gd
│   └── persistence/      # Data storage
│       ├── game_state.gd
│       └── player_profile.gd
│
└── presentation/         # PRESENTATION LAYER
    ├── main_game.gd     # COORDINATOR ONLY
    ├── ui/              # User interface
    │   ├── skip_turn_button.gd
    │   ├── action_label.gd
    │   └── tech_tree_ui.gd
    └── scenes/          # Godot scenes
        ├── game_scene.tscn
        └── menu_scene.tscn
```

---

## 🎮 ENTITY SPECIFICATIONS

### 🔷 CORE ENTITIES

#### HEX_POINT
```gdscript
# Purpose: Individual hexagonal grid point
# Properties: position, coordinate, connections
# Methods: get_neighbors(), calculate_distance()
```

#### UNIT
```gdscript
# Purpose: Game unit (replicable)
# Properties: position, actions, owner, visibility
# Methods: move(), consume_action(), reveal()
```

#### DOMAIN
```gdscript
# Purpose: Player territory (replicable)
# Properties: center, power, owner, influence_area
# Methods: generate_power(), consume_power(), expand()
```

#### TECHNOLOGY
```gdscript
# Purpose: Tech tree node
# Properties: prerequisites, unlocks, cost
# Methods: can_research(), unlock_permissions()
```

#### STRUCTURE
```gdscript
# Purpose: Buildable structure (replicable)
# Properties: type, position, effects, owner
# Methods: build(), upgrade(), destroy()
```

### 🔷 VALUE OBJECTS

#### HEX_COORDINATE
```gdscript
# Purpose: Immutable axial coordinate (q, r)
# Methods: to_pixel(), distance_to(), add()
```

#### PERMISSION
```gdscript
# Purpose: Unlocked capability
# Properties: type, target, conditions
```

---

## 🚀 IMPLEMENTATION PHASES

### PHASE 1: CORE FOUNDATION (Day 1 Morning)
```
TASKS:
1. Create folder structure
2. Implement core entities:
   - HexPoint, HexCoordinate
   - Unit, Domain, Player
   - Technology, Structure
3. Create value objects:
   - Position, Permission
   - GameConstants
4. Basic entity tests

DELIVERABLE: Core entities with basic functionality
```

### PHASE 2: APPLICATION LAYER (Day 1 Afternoon)
```
TASKS:
1. Implement services:
   - GridService (grid generation)
   - MovementService (unit movement)
   - VisibilityService (fog of war)
   - TurnService (player turns)
2. Create use cases:
   - MoveUnit, SkipTurn
   - ToggleFog, GenerateTerrain
3. Service integration tests

DELIVERABLE: Business logic layer complete
```

### PHASE 3: INFRASTRUCTURE (Day 2 Morning)
```
TASKS:
1. Input handling:
   - MouseHandler, KeyboardHandler
   - InputManager coordination
2. Rendering system:
   - GridRenderer, UnitRenderer
   - DomainRenderer, UIRenderer
3. Basic networking foundation:
   - NetworkManager, GameServer
4. Game state persistence

DELIVERABLE: Infrastructure layer complete
```

### PHASE 4: PRESENTATION & INTEGRATION (Day 2 Afternoon)
```
TASKS:
1. Main game coordinator:
   - Wire all layers together
   - Event handling
2. UI components:
   - SkipTurnButton, ActionLabel
   - TechTreeUI, StructurePanel
3. Scene setup:
   - GameScene, MenuScene
4. Integration testing

DELIVERABLE: Fully functional modular game
```

### PHASE 5: MULTIPLAYER FOUNDATION (Future)
```
TASKS:
1. Network synchronization
2. Matchmaking system
3. Anti-cheat basics
4. Performance optimization

DELIVERABLE: Multiplayer-ready architecture
```

---

## 🎯 QODO ASSISTANT GUIDELINES

### ✅ MANDATORY RULES
1. **READ THIS ENTIRE DOCUMENT** before starting implementation
2. **FOLLOW ONION ARCHITECTURE** - never violate layer dependencies
3. **IMPLEMENT PHASE BY PHASE** - do not skip phases
4. **ONE FUNCTION PER FILE** - maximum granularity
5. **TEST EACH COMPONENT** - ensure testability

### 🚨 CRITICAL ALERTS
- **NEVER CREATE MONOLITHS** - If file > 200 lines, refactor immediately
- **NEVER VIOLATE LAYERS** - Dependencies must always point inward
- **ALWAYS CONSIDER MULTIPLAYER** - Every decision must support networking
- **ALWAYS PLAN FOR SCALING** - Support N players/units/domains

### 📝 DOCUMENTATION REQUIREMENTS
```
EACH FILE MUST HAVE:
- Header comment explaining purpose
- Class responsibility documentation
- Public method documentation
- Architectural decision justification
```

### 🔄 IMPLEMENTATION PROCESS
```
FOR EACH COMPONENT:
1. Create file with proper header
2. Implement minimal functionality
3. Add tests
4. Document decisions
5. Integrate with existing system
6. Verify no layer violations
```

### 🧪 TESTING STRATEGY
```
EACH ENTITY MUST BE:
- Unit testable in isolation
- Integration testable with dependencies
- Performance tested for scalability
```

---

## 📊 SUCCESS CRITERIA

### ✅ PHASE COMPLETION CHECKLIST
```
PHASE 1 COMPLETE WHEN:
- All core entities implemented
- Value objects functional
- Basic tests passing
- No monolithic files

PHASE 2 COMPLETE WHEN:
- All services implemented
- Use cases functional
- Business logic tests passing
- Layer dependencies correct

PHASE 3 COMPLETE WHEN:
- Input/rendering working
- Network foundation ready
- Infrastructure tests passing
- Performance acceptable

PHASE 4 COMPLETE WHEN:
- Game fully functional
- All features working
- Integration tests passing
- Ready for multiplayer expansion
```

### 🎯 FINAL DELIVERABLE
```
MODULAR V&V GAME WITH:
- Zero monolithic files
- Clean ONION architecture
- Multiplayer-ready foundation
- Scalable to N players/units/domains
- All original features preserved
- New features easily addable
```

---

**🛡️ BLUEPRINT STATUS: READY FOR QODO IMPLEMENTATION 🚀**

> **NEXT ACTION**: Begin Phase 1 - Core Foundation