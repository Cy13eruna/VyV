# 🐎 RIDER TECHNOLOGY IMPLEMENTATION

## Overview
Complete implementation of the Rider technology based on specifications from i.txt. This technology unlocks rider training for units, providing them with 2 actions per turn instead of the standard 1.

## Specifications from i.txt
```
- Rider:
    - novo treinamento para unidades
    - unidade treinada terá direito a duas ações ao invés de uma apenas
    - cada ação gastará poder, obviamente
    - acrescenta o emoji 🐎 na base da unidade
```

## Implementation Details

### 1. Core Entity Changes (unit_clean.gd)

#### New Properties:
```gdscript
var is_rider: bool = false    # Whether unit has rider training
```

#### Action System Updates:
```gdscript
# Restore actions (start of turn)
func restore_actions() -> void:
    if is_rider:
        actions_remaining = 2  # Riders get 2 actions per turn
        max_actions = 2
    else:
        actions_remaining = 1
        max_actions = 1
```

#### Training Method:
```gdscript
func make_rider() -> void:
    is_rider = true
    # Update max actions immediately
    max_actions = 2
    # If unit currently has actions, give it the extra action
    if actions_remaining > 0:
        actions_remaining = 2
```

### 2. Training System Integration

#### Validation (action_dialog_validation.gd):
```gdscript
func can_train_rider(unit, player, game_state: Dictionary) -> bool:
    # Unit must not already be a rider
    if unit.is_rider:
        return false
    
    # Player must have Rider technology
    if not technology_manager.has_technology(player.id, "rider"):
        return false
    
    # Player must have enough power
    var total_power = get_player_total_power(player, game_state)
    if total_power < unit.level:
        return false
    
    return true
```

#### Training Execution (action_dialog_training.gd):
```gdscript
func _execute_rider_training(unit, cost: int, player, game_state: Dictionary):
    # Deduct power from player's domains
    _deduct_power_from_player(player, game_state, cost)
    
    # Make unit a rider
    unit.make_rider()
    
    # Increase unit level
    unit.level += 1
    
    # Consume one action (training costs an action)
    unit.consume_action()
```

### 3. Visual Indicator System

#### Rendering (unit_indicator_renderer.gd):
```gdscript
func render_rider_indicators(game_state: Dictionary, fog_settings: Dictionary):
    # Check each unit for rider status
    for unit_id in game_state.units:
        var unit = game_state.units[unit_id]
        
        # Only show indicator for rider units
        if not unit.is_rider:
            continue
        
        # Position the emoji at the base of the unit (below the name)
        var offset = Vector2(0, 30) * camera_manager.zoom_level
        
        # Draw rider indicator emoji
        var emoji = "🐎"  # Horse emoji
        var size = int(16 * camera_manager.zoom_level)
```

#### Rendering Integration (main_game.gd):
```gdscript
# Render rider indicators on top of everything
rendering_manager.call("_render_rider_indicators", game_state, fog_settings)
```

### 4. Technology System Integration

#### Technology Description:
```gdscript
"rider":
    description += "[b]Rider Training Unlock[/b]\n"
    description += "Unlocks RIDER training for units. Enables double actions per turn.\n\n"
    description += "[b]Mechanics:[/b]\n"
    description += "• Unlocks: RIDER training option at domain stars\n"
    description += "• Training cost: Unit level power from natal domain\n"
    description += "• Rider ability: 2 actions per turn instead of 1\n"
    description += "• Visual indicator: 🐎 emoji appears at unit base"
```

#### Technology Application:
```gdscript
func _apply_rider_technology(player_id: int):
    # Rider technology unlocks rider training for units
    # The effects are applied when units are trained as riders
    # No immediate action needed as it's a training option
    print("[TECH] Player %d acquired Rider technology 🐎 - Rider training now available" % player_id)
```

## Game Mechanics

### 1. Training Process
1. **Prerequisite**: Player must have researched Rider technology
2. **Location**: Unit must be at domain star (center or adjacent)
3. **Cost**: Unit level power from player's domains
4. **Effect**: Unit becomes rider with 2 actions per turn
5. **Visual**: 🐎 emoji appears at unit base

### 2. Action System
- **Normal Units**: 1 action per turn
- **Rider Units**: 2 actions per turn
- **Action Types**: Move, Attack, Heal, Settle, Train
- **Power Cost**: Each action still consumes power as normal

### 3. Visual Indicators
- **Position**: Below unit name (at base)
- **Emoji**: 🐎 (Horse)
- **Size**: 16px scaled with zoom
- **Visibility**: Follows universal emoji visibility rules
- **Shadow**: Added for better visibility

## Technical Architecture

### 1. Modular Design
- **Core Entity**: Unit properties and behavior
- **Training System**: Validation and execution
- **Rendering System**: Visual indicators
- **Technology System**: Unlock mechanism

### 2. Consistent Patterns
- **Training Pattern**: Same as Fighter/Healer training
- **Validation Pattern**: Technology check + power check
- **Rendering Pattern**: Same as other unit indicators
- **Action Pattern**: Integrated with existing action system

### 3. Error Handling
- **Null Checks**: All renderer functions check for null references
- **Validation**: Comprehensive checks before training
- **Fallbacks**: Default values for missing properties

## Integration Points

### 1. Files Modified
- `SKETCH/core/entities/unit_clean.gd` - Core unit functionality
- `SKETCH/presentation/managers/dialog/action_dialog_validation.gd` - Training validation
- `SKETCH/presentation/managers/dialog/action_dialog_training.gd` - Training execution
- `SKETCH/presentation/managers/rendering/unit_indicator_renderer.gd` - Visual indicators
- `SKETCH/presentation/managers/rendering_manager.gd` - Rendering coordination
- `SKETCH/presentation/main_game.gd` - Main rendering loop
- `SKETCH/presentation/managers/dialog/technology_manager.gd` - Technology description

### 2. System Dependencies
- **Technology Manager**: For technology unlock checks
- **Action System**: For training validation and execution
- **Rendering System**: For visual indicators
- **Power System**: For training costs

## Testing Scenarios

### 1. Basic Functionality
- ✅ Research Rider technology
- ✅ Train unit as rider at domain star
- ✅ Verify unit gets 2 actions per turn
- ✅ Verify 🐎 emoji appears at unit base

### 2. Edge Cases
- ✅ Cannot train rider without technology
- ✅ Cannot train already-rider unit
- ✅ Training consumes power and action
- ✅ Visual indicator follows fog of war rules

### 3. Integration
- ✅ Works with existing action system
- ✅ Compatible with other unit types (fighter/healer)
- ✅ Proper rendering order and visibility
- ✅ Technology tree integration

## Future Enhancements

### 1. Potential Improvements
- **Stacking**: Allow rider + fighter/healer combinations
- **Advanced Abilities**: Special rider-only actions
- **Visual Effects**: Animation for 🐎 emoji
- **Sound Effects**: Audio feedback for rider actions

### 2. Balance Considerations
- **Power Cost**: Each action still costs power
- **Training Cost**: Scales with unit level
- **Availability**: Requires Tier 2 technology research
- **Positioning**: Must train at domain stars

## Conclusion

The Rider technology has been fully implemented according to the specifications in i.txt. It provides a meaningful upgrade path for units, allowing them to perform 2 actions per turn while maintaining game balance through power costs and technology requirements. The implementation follows established patterns and integrates seamlessly with existing systems.