# 🚀 REFACTORING PLAN - PHASE 3 (Steps 10-15)
## FINAL DEMONOLITHIZATION ROADMAP

### 📊 CURRENT STATE ANALYSIS
**Target Files for Breakdown:**
- `main_game.gd` - **1,517 lines** 🔥 MASSIVE MONOLITH
- `game_manager.gd` - 461 lines 
- `unit_system.gd` - 547 lines
- `ui_system.gd` - 379 lines  
- `render_system.gd` - 320 lines

**Total Lines to Refactor:** 3,224 lines
**Current Architecture:** 9 systems created, but main_game.gd still contains massive fallback logic

---

## 🎯 STEP 10: EXTRACT VISIBILITY SYSTEM
**Target:** `main_game.gd` visibility logic → `systems/visibility_system.gd`
**Lines to Extract:** ~200 lines
**Functions to Move:**
- `_is_point_visible_to_current_unit()`
- `_is_point_visible_to_unit()`
- `_is_domain_visible()`
- `_is_point_in_current_player_domain()`
- `_is_path_in_current_player_domain()`
- `_is_point_in_specific_domain()`
- `_check_and_reset_forced_revelations()`

**Benefits:**
- Centralized fog of war logic
- Cleaner domain visibility management
- Reduced main_game.gd complexity

---

## 🎯 STEP 11: EXTRACT MOVEMENT SYSTEM  
**Target:** `main_game.gd` movement logic → `systems/movement_system.gd`
**Lines to Extract:** ~150 lines
**Functions to Move:**
- `_can_current_unit_move_to_point()`
- `_can_unit_move_to_point()`
- `_attempt_movement()`
- `_get_path_type_between_points()`
- `_handle_movement_fallback()`

**Benefits:**
- Isolated movement validation
- Cleaner collision detection
- Separated forest mechanics

---

## 🎯 STEP 12: EXTRACT GRID GENERATION SYSTEM
**Target:** `main_game.gd` grid logic → `systems/grid_generation_system.gd`
**Lines to Extract:** ~300 lines
**Functions to Move:**
- `_generate_hex_grid()`
- `_hex_to_pixel()`
- `_hex_direction()`
- `_generate_hex_paths()`
- `_find_hex_coord_index()`
- `_hex_distance()`
- `_get_map_corners()`
- `_mark_map_corners()`

**Benefits:**
- Complete grid generation isolation
- Mathematical utilities centralized
- Coordinate system management

---

## 🎯 STEP 13: EXTRACT POSITIONING SYSTEM
**Target:** `main_game.gd` positioning logic → `systems/positioning_system.gd`
**Lines to Extract:** ~250 lines
**Functions to Move:**
- `_set_initial_unit_positions()`
- `_find_adjacent_six_edge_point()`
- `_find_best_domain_positions()`
- `_analyze_grid_connectivity()`
- `_generate_domain_and_unit_names()`
- `_get_domain_index()`

**Benefits:**
- Intelligent spawn positioning
- Domain placement algorithms
- Name generation system

---

## 🎯 STEP 14: EXTRACT FALLBACK SYSTEM
**Target:** `main_game.gd` fallback logic → `systems/fallback_system.gd`
**Lines to Extract:** ~400 lines
**Functions to Move:**
- All `_*_fallback()` functions
- `_process_hover_fallback()`
- `_handle_input_fallback()`
- `_draw_fallback()`
- `_create_ui_fallback()`
- `_handle_skip_turn_fallback()`

**Benefits:**
- Centralized fallback management
- Cleaner error handling
- Backward compatibility layer

---

## 🎯 STEP 15: EXTRACT DRAWING SYSTEM
**Target:** `main_game.gd` drawing logic → `systems/drawing_system.gd`
**Lines to Extract:** ~200 lines
**Functions to Move:**
- `_draw_domains()`
- `_draw_domain_hexagon()`
- `_get_edge_length()`
- `_get_path_color()`
- `_point_near_line()`

**Benefits:**
- Separated rendering concerns
- Modular drawing utilities
- Visual effects isolation

---

## 📈 PROJECTED RESULTS AFTER PHASE 3

### Before Phase 3:
- `main_game.gd`: 1,517 lines
- Total systems: 9
- Monolithic complexity: HIGH

### After Phase 3:
- `main_game.gd`: ~200 lines (87% reduction!)
- Total systems: 15
- Monolithic complexity: MINIMAL

### New Systems Created:
10. `VisibilitySystem` - Fog of war & domain visibility
11. `MovementSystem` - Movement validation & collision
12. `GridGenerationSystem` - Grid creation & coordinates  
13. `PositioningSystem` - Spawn positioning & naming
14. `FallbackSystem` - Backward compatibility
15. `DrawingSystem` - Visual rendering utilities

---

## 🔧 IMPLEMENTATION STRATEGY

### Risk Mitigation:
1. **Backup before each step** - Create `main_game_step_X_backup.gd`
2. **Incremental testing** - Test after each extraction
3. **Signal-based communication** - Maintain loose coupling
4. **Fallback preservation** - Keep compatibility layers
5. **Autoload integration** - Use established pattern

### Testing Protocol:
1. Run game after each step
2. Verify all UI elements functional
3. Test movement and visibility
4. Confirm power system integration
5. Validate fog of war mechanics

### Success Metrics:
- ✅ Game remains fully functional
- ✅ All labels and UI working
- ✅ No performance degradation
- ✅ Clean modular architecture
- ✅ 87% reduction in main file size

---

## 🎯 EXECUTION ORDER

**Priority:** Steps 10-12 (Core systems)
**Secondary:** Steps 13-15 (Optimization systems)

**Estimated Time:** 2-3 hours total
**Risk Level:** MEDIUM (established patterns reduce risk)
**Success Probability:** HIGH (proven methodology)

---

*Ready to execute Step 10 - Visibility System extraction!*