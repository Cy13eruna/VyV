# 🔧 REFACTORING PLAN - BREAKING THE MONOLITH

## ⚠️ IDENTIFIED PROBLEM
**Previous attempts failed**: Units and unit/domain titles disappeared
**Root cause**: Loss of Label references during refactoring

## 🎯 LABEL PRESERVATION STRATEGY

### Fundamental Principles:
1. **GameManager centralizes all Label references**
2. **Systems communicate via signals, don't manipulate Labels directly**
3. **Centralized state in GameState**
4. **Controlled and ordered initialization**
5. **Test after each step**

## 📁 PROPOSED FINAL STRUCTURE

```
SKETCH/
├── minimal_triangle.tscn (keep as main scene)
├── game_manager.gd (new - coordinates everything and maintains Labels)
├── systems/
│   ├── terrain_system.gd
│   ├── hex_grid_system.gd
│   ├── input_system.gd
│   ├── render_system.gd
│   ├── ui_system.gd
│   ├── unit_system.gd (CRITICAL - movement, positions)
│   ├── domain_system.gd (CRITICAL - domains, power, names)
│   └── visibility_system.gd (CRITICAL - fog of war)
└── data/
    ├── game_state.gd (shared state)
    └── constants.gd (enums, constants)
```

## 🚀 IMPLEMENTATION SCHEDULE

### STEP 1: Base Preparation (WITHOUT BREAKING ANYTHING)
**Objective**: Create structure without affecting functionality
**Actions**:
- [ ] Create backup: `cp minimal_triangle.gd minimal_triangle_backup.gd`
- [ ] Create directories: `systems/` and `data/`
- [ ] Create `data/constants.gd` with EdgeType enum
- [ ] Create `data/game_state.gd` with all state variables
- [ ] **TEST**: Verify everything still works

### STEP 2: Extract TerrainSystem (LOW RISK)
**Objective**: First system, less critical
**Actions**:
- [ ] Create `systems/terrain_system.gd`
- [ ] Move: EdgeType enum, _generate_random_terrain(), _get_path_color()
- [ ] Integrate into minimal_triangle.gd
- [ ] **TEST**: Verify random terrain and colors

### STEP 3: Extract HexGridSystem (LOW RISK)
**Objective**: Coordinate system
**Actions**:
- [ ] Create `systems/hex_grid_system.gd`
- [ ] Move: _generate_hex_grid(), _hex_to_pixel(), coordinates
- [ ] **TEST**: Verify points and paths appear correctly

### STEP 4: Create GameManager (CRITICAL PREPARATION)
**Objective**: Centralize Label control
**Actions**:
- [ ] Create `game_manager.gd`
- [ ] Move ALL Label references to GameManager
- [ ] Establish signal system between systems
- [ ] **CRITICAL TEST**: Verify ALL labels appear and function

### STEP 5: Extract InputSystem (MEDIUM RISK)
**Objective**: Separate input logic
**Actions**:
- [ ] Create `systems/input_system.gd`
- [ ] Move: _unhandled_input(), mouse/keyboard handling
- [ ] **TEST**: Verify movement and controls

### STEP 6: Extract RenderSystem (MEDIUM RISK)
**Objective**: Separate rendering logic
**Actions**:
- [ ] Create `systems/render_system.gd`
- [ ] Move: _draw(), color and rendering logic
- [ ] **TEST**: Verify everything renders correctly

### STEP 7: Extract UISystem (MEDIUM RISK)
**Objective**: Separate user interface
**Actions**:
- [ ] Create `systems/ui_system.gd`
- [ ] Move: _create_ui(), buttons, action_label
- [ ] **TEST**: Verify buttons and interface

### STEP 8: Extract UnitSystem (HIGH RISK - CRITICAL)
**Objective**: Unit system
**Actions**:
- [ ] Create `systems/unit_system.gd`
- [ ] Move: positions, movement, unit actions
- [ ] **MAINTAIN**: Label references in GameManager
- [ ] **CRITICAL TEST**: Verify units appear and move

### STEP 9: Extract DomainSystem (HIGH RISK - CRITICAL)
**Objective**: Domain system
**Actions**:
- [ ] Create `systems/domain_system.gd`
- [ ] Move: domains, power, name generation
- [ ] **MAINTAIN**: Label references in GameManager
- [ ] **CRITICAL TEST**: Verify domain names and power

### STEP 10: Extract VisibilitySystem (HIGH RISK - CRITICAL)
**Objective**: Visibility system
**Actions**:
- [ ] Create `systems/visibility_system.gd`
- [ ] Move: fog of war, point/path visibility
- [ ] **CRITICAL TEST**: Verify fog of war and label visibility

## 🔍 SUCCESS CRITERIA FOR EACH TEST

### Mandatory Checklist:
- [ ] ✅ Units appear (red and violet emojis)
- [ ] ✅ Unit names appear below emojis
- [ ] ✅ Domain names appear with power (⚡)
- [ ] ✅ Movement works (click on magenta points)
- [ ] ✅ Fog of war works (SPACE toggle)
- [ ] ✅ UI works (Skip Turn, action counter)
- [ ] ✅ Input works (mouse, keyboard)
- [ ] ✅ Random terrain works
- [ ] ✅ Domains appear (colored hexagons)
- [ ] ✅ Power system works

## 🚨 CRITICAL ATTENTION POINTS

### Labels that CANNOT disappear:
1. `unit1_label` - Unit 1 emoji
2. `unit2_label` - Unit 2 emoji
3. `unit1_name_label` - Unit 1 name
4. `unit2_name_label` - Unit 2 name
5. `unit1_domain_label` - Domain 1 name + power
6. `unit2_domain_label` - Domain 2 name + power
7. `action_label` - Action counter
8. `skip_turn_button` - Skip turn button

### Critical functions that update Labels:
- `_update_units_visibility_and_position()`
- `_update_name_positions()`
- `_update_action_display()`

## 🔄 ROLLBACK PLAN

**At each step**: Maintain functional backup
**If something goes wrong**: Return to previous backup
**Backup command**: `cp minimal_triangle.gd minimal_triangle_step_X.gd`

## 📋 INTER-SYSTEM COMMUNICATION (VIA SIGNALS)

```gdscript
# Examples of signals that systems should emit:
signal unit_moved(unit_id, old_pos, new_pos)
signal unit_visibility_changed(unit_id, visible)
signal domain_power_changed(domain_id, power)
signal terrain_generated()
signal fog_toggled(enabled)
```

**GameManager listens to all signals and updates appropriate Labels.**

---

## ⚡ IMPLEMENTATION START

**Next step**: Execute STEP 1 - Base Preparation
**Command**: Start by creating backup and directory structure