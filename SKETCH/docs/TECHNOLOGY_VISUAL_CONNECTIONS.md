# 🔗 TECHNOLOGY VISUAL CONNECTIONS

## Overview
The technology tree now includes visual connection lines that clearly show the dependencies between technologies. These connections help players understand the prerequisite relationships and plan their technology progression.

## Visual Elements

### Connection Lines
- **Implementation**: ColorRect elements positioned and rotated to create lines
- **Thickness**: 2 pixels for clear visibility
- **Positioning**: Lines connect the center points of technology buttons
- **Layering**: Lines appear behind technology buttons to avoid interference

### Arrow Indicators
- **Symbol**: ▶ (right-pointing triangle)
- **Purpose**: Shows the direction of dependency (from prerequisite to advanced tech)
- **Positioning**: Offset 25 pixels from the target button edge
- **Rotation**: Aligned with the connection line direction

## Color Coding System

### Line Colors
The connection lines use different colors to indicate the status of technology relationships:

#### 🟢 Green Lines (`Color(0.2, 0.8, 0.2, 0.8)`)
- **Meaning**: Technology is already obtained
- **Status**: Both prerequisite and advanced technology are researched
- **Visual**: Bright green with 80% opacity

#### 🔵 Blue Lines (`Color(0.2, 0.5, 1.0, 0.8)`)
- **Meaning**: Technology is available for research
- **Status**: Prerequisite is met, advanced technology can be researched
- **Visual**: Bright blue with 80% opacity

#### ⚫ Gray Lines (`Color(0.5, 0.5, 0.5, 0.5)`)
- **Meaning**: Technology is not yet available
- **Status**: Prerequisite has not been researched yet
- **Visual**: Gray with 50% opacity (more transparent)

## Technical Implementation

### Connection Drawing Process
1. **Position Storage**: Technology positions are stored during button creation
2. **Line Creation**: For each Tier 2 technology, create connection to its prerequisite
3. **Color Determination**: Check player's technology status to determine line color
4. **Visual Creation**: Create ColorRect for line and Label for arrow
5. **Layering**: Ensure lines appear behind buttons but arrows are visible

### Key Functions
- `_draw_technology_connections()` - Main coordination function
- `_create_connection_line()` - Creates individual connection lines
- `_create_arrow_indicator()` - Creates directional arrows
- `_get_connection_line_color()` - Determines line color based on status

### UI Hierarchy
```
tech_container
├── connection_lines (ColorRect elements) - Layer 0
├── arrow_indicators (Label elements) - Layer 1
└── technology_buttons (Button containers) - Layer 2+
```

## Dependency Mapping

### Settler Branches
- **🚩 Settler** → **🐎 Rider**
- **🚩 Settler** → **🤝🏻 Market**

### Harvest Branches
- **🧺 Harvest** → **⛰ Climber**
- **🧺 Harvest** → **🏘 Hamlet**

### Healer Branches
- **♥ Healer** → **🪽 Shaman**
- **♥ Healer** → **🛡 Guardian**

### Fighter Branches
- **🗡 Fighter** → **🪓 Warrior**
- **🗡 Fighter** → **🏹 Archer**

### Fish Branches
- **🎣 Fish** → **〰 Sailor**
- **🎣 Fish** → **🐋 Whale**

## User Experience Benefits

### Clarity
- **Visual Hierarchy**: Clear distinction between available and unavailable paths
- **Progress Tracking**: Easy to see which technologies have been researched
- **Planning**: Players can visualize their technology progression strategy

### Accessibility
- **Color Coding**: Multiple visual cues (color + opacity) for different states
- **Non-Intrusive**: Lines don't interfere with button interactions
- **Clear Direction**: Arrows show the flow from prerequisite to advanced tech

## Performance Considerations

### Efficient Rendering
- **Static Elements**: Lines are created once and don't require constant updates
- **Minimal Overhead**: Uses simple UI elements (ColorRect, Label) instead of custom drawing
- **Layered Approach**: Proper z-ordering ensures correct visual hierarchy

### Memory Usage
- **Lightweight**: Each connection uses only 2 UI elements (line + arrow)
- **No Custom Shaders**: Uses built-in Godot UI components
- **Cleanup**: Elements are automatically cleaned up when dialog closes

## Future Enhancements

### Potential Improvements
- **Animated Lines**: Could add subtle animations for newly available technologies
- **Hover Effects**: Highlight connection paths when hovering over technologies
- **Curved Lines**: More sophisticated line routing for complex dependency trees
- **Status Icons**: Additional visual indicators for technology effects

### Scalability
- **Additional Tiers**: System can easily accommodate more technology tiers
- **Complex Dependencies**: Can handle technologies with multiple prerequisites
- **Dynamic Updates**: Lines can be updated in real-time as technologies are researched

## Code Maintenance

### Modular Design
- **Separation of Concerns**: Line drawing is separate from button creation
- **Reusable Functions**: Connection creation functions can be reused
- **Clear Interfaces**: Well-defined parameters for customization

### Configuration
- **Color Constants**: Easy to modify line colors for different themes
- **Size Parameters**: Line thickness and arrow size can be adjusted
- **Positioning**: Offset values can be tuned for different layouts

The visual connection system significantly improves the user experience by making technology dependencies immediately clear and intuitive to understand.