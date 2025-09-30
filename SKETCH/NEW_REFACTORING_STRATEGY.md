# 🔄 NEW REFACTORING STRATEGY - KEEP MAIN_GAME.GD INTACT

## 🚨 **PROBLEM ANALYSIS**
The previous approach **FAILED** because it tried to **extract code FROM** `main_game.gd`, which:
- Broke the monolithic structure
- Created integration issues
- Lost the working state
- Required complex autoload configurations

## 🎯 **NEW STRATEGY: WRAPPER ARCHITECTURE**

### **CORE PRINCIPLE**: 
**KEEP `main_game.gd` COMPLETELY UNTOUCHED** while creating a **WRAPPER LAYER** that provides modular access to its functionality.

## 🏗️ **ARCHITECTURE DESIGN**

```
SKETCH/
├── main_game.gd                    # ✅ UNTOUCHED MONOLITH
├── main_game.tscn                  # ✅ UNTOUCHED SCENE
├── managers/                       # 🆕 NEW WRAPPER LAYER
│   ├── grid_manager.gd            # Wraps grid functions
│   ├── terrain_manager.gd         # Wraps terrain functions  
│   ├── movement_manager.gd        # Wraps movement functions
│   ├── ui_manager.gd              # Wraps UI functions
│   ├── render_manager.gd          # Wraps render functions
│   ├── input_manager.gd           # Wraps input functions
│   └── game_manager.gd            # Wraps game logic functions
├── interfaces/                     # 🆕 CLEAN INTERFACES
│   ├── i_grid.gd                  # Grid interface
│   ├── i_terrain.gd               # Terrain interface
│   ├── i_movement.gd              # Movement interface
│   └── i_game_state.gd            # Game state interface
└── utils/                          # 🆕 UTILITY FUNCTIONS
    ├── hex_math.gd                # Hexagonal math utilities
    ├── color_utils.gd             # Color management
    └── constants.gd               # Game constants
```

## 📋 **IMPLEMENTATION STRATEGY**

### **PHASE 1: CREATE WRAPPER MANAGERS (NO CHANGES TO MAIN)**

#### **Step 1: GridManager Wrapper**
```gdscript
# managers/grid_manager.gd
class_name GridManager
extends RefCounted

var main_game_ref: Node2D

func _init(main_game: Node2D):
    main_game_ref = main_game

func get_hex_coords() -> Array:
    return main_game_ref.hex_coords

func hex_to_pixel(hex_coord: Vector2) -> Vector2:
    return main_game_ref._hex_to_pixel(hex_coord)

func find_hex_coord_index(target_coord: Vector2) -> int:
    return main_game_ref._find_hex_coord_index(target_coord)
```

#### **Step 2: TerrainManager Wrapper**
```gdscript
# managers/terrain_manager.gd
class_name TerrainManager
extends RefCounted

var main_game_ref: Node2D

func _init(main_game: Node2D):
    main_game_ref = main_game

func get_path_color(edge_type: int) -> Color:
    return main_game_ref._get_path_color(edge_type)

func get_edge_type(edge_index: int) -> int:
    return main_game_ref.paths[edge_index].type
```

#### **Step 3: MovementManager Wrapper**
```gdscript
# managers/movement_manager.gd
class_name MovementManager
extends RefCounted

var main_game_ref: Node2D

func _init(main_game: Node2D):
    main_game_ref = main_game

func can_move_to(point_index: int) -> bool:
    return main_game_ref._can_unit_move_to_point(point_index)

func try_move(point_index: int) -> bool:
    return main_game_ref._attempt_movement(point_index)
```

### **PHASE 2: CREATE CLEAN INTERFACES**

#### **Interface Example:**
```gdscript
# interfaces/i_grid.gd
class_name IGrid
extends RefCounted

# Abstract interface for grid operations
func get_point_count() -> int:
    assert(false, \"Must be implemented by subclass\")
    return 0

func get_point_position(index: int) -> Vector2:
    assert(false, \"Must be implemented by subclass\")
    return Vector2.ZERO

func get_adjacent_points(index: int) -> Array[int]:
    assert(false, \"Must be implemented by subclass\")
    return []
```

### **PHASE 3: CREATE FACADE LAYER**

#### **Main Facade:**
```gdscript
# game_facade.gd
class_name GameFacade
extends RefCounted

var grid_manager: GridManager
var terrain_manager: TerrainManager
var movement_manager: MovementManager
var main_game_ref: Node2D

func _init(main_game: Node2D):
    main_game_ref = main_game
    grid_manager = GridManager.new(main_game)
    terrain_manager = TerrainManager.new(main_game)
    movement_manager = MovementManager.new(main_game)

# Clean API for external use
func get_grid_size() -> int:
    return grid_manager.get_hex_coords().size()

func move_current_unit(target_point: int) -> bool:
    if movement_manager.can_move_to(target_point):
        return movement_manager.try_move(target_point)
    return false
```

## 🔧 **IMPLEMENTATION STEPS**

### **STEP 1: Create Manager Wrappers (SAFE)**
- Create `managers/` folder
- Create wrapper classes that reference `main_game.gd`
- **NO CHANGES** to `main_game.gd`
- Test each wrapper individually

### **STEP 2: Create Interfaces (SAFE)**
- Create `interfaces/` folder  
- Define clean interfaces for each subsystem
- **NO CHANGES** to `main_game.gd`
- Document expected behavior

### **STEP 3: Create Utilities (SAFE)**
- Create `utils/` folder
- Extract pure functions (math, colors, constants)
- **NO CHANGES** to `main_game.gd`
- Test utility functions

### **STEP 4: Create Facade (SAFE)**
- Create main facade class
- Provide clean API over wrapper layer
- **NO CHANGES** to `main_game.gd`
- Test facade functionality

### **STEP 5: Optional Migration Layer**
- Create migration utilities
- Allow gradual transition to new API
- **STILL NO CHANGES** to `main_game.gd`
- Maintain backward compatibility

## ✅ **ADVANTAGES OF THIS APPROACH**

### **1. ZERO RISK**
- `main_game.gd` remains completely untouched
- Original functionality preserved 100%
- Can rollback at any time

### **2. GRADUAL ADOPTION**
- New code can use clean interfaces
- Old code continues working
- Migration can happen over time

### **3. CLEAN ARCHITECTURE**
- Separation of concerns through wrappers
- Clean interfaces for testing
- Modular design without breaking changes

### **4. FUTURE FLEXIBILITY**
- Can eventually replace implementations
- Easy to add new features
- Testable components

## 🚨 **CRITICAL RULES**

### **NEVER MODIFY `main_game.gd`**
- No code extraction
- No function removal
- No variable changes
- No refactoring

### **WRAPPER ONLY APPROACH**
- All managers are wrappers
- All access goes through wrappers
- Original code stays intact

### **INCREMENTAL TESTING**
- Test each wrapper individually
- Verify functionality preservation
- No breaking changes allowed

## 🎯 **SUCCESS CRITERIA**

### **Phase 1 Complete:**
- ✅ All managers created and tested
- ✅ `main_game.gd` completely unchanged
- ✅ Game functionality identical
- ✅ Clean wrapper interfaces

### **Phase 2 Complete:**
- ✅ Clean interfaces defined
- ✅ Utility functions extracted
- ✅ Documentation complete
- ✅ Zero breaking changes

### **Phase 3 Complete:**
- ✅ Facade layer functional
- ✅ Clean API available
- ✅ Migration path clear
- ✅ Original code preserved

---

**NEXT ACTION**: Start with **STEP 1** - Create the first wrapper manager (GridManager)