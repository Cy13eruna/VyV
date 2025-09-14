# Vagabonds & Valleys - Hexagonal Grid System v2.0

## 📋 Overview

This project implements a high-performance hexagonal grid system for the "Vagabonds & Valleys" strategy game. The system features modular architecture, intelligent caching, optimized rendering, and comprehensive configuration management.

## 🏗️ Architecture

### Component-Based Design

The system is built using a modular architecture with clear separation of concerns:

```
HexGridV2 (Main Controller)
├── HexGridConfig (Configuration & Validation)
├── HexGridGeometry (Mathematical Calculations)
├── HexGridCache (Intelligent Caching)
└── HexGridRenderer (Optimized Rendering)
```

### Class Responsibilities

#### 🔧 HexGridConfig
- **Purpose**: Centralized configuration management with validation
- **Features**:
  - Input validation with constraints
  - Change detection and notifications
  - Serialization support (to/from Dictionary)
  - Automatic dirty flag management

#### 📐 HexGridGeometry
- **Purpose**: All geometric calculations for hexagonal grids
- **Features**:
  - Perfect hexagon tiling calculations
  - Vertex and connection geometry
  - Rotation and transformation utilities
  - Spatial relationship calculations
  - Trigonometric caching for performance

#### 💾 HexGridCache
- **Purpose**: Intelligent caching system for pre-calculated data
- **Features**:
  - Automatic cache invalidation on configuration changes
  - Spatial grid for fast neighbor lookup
  - Memory usage tracking
  - Performance metrics and statistics
  - Configurable cache size limits

#### 🎨 HexGridRenderer
- **Purpose**: Optimized rendering with culling and LOD
- **Features**:
  - Layered rendering system
  - Viewport culling for performance
  - Level of detail (LOD) support
  - Batch rendering optimizations
  - Performance monitoring and auto-optimization

#### 🎯 HexGridV2
- **Purpose**: Main orchestrator that coordinates all components
- **Features**:
  - Unified API for grid operations
  - Event system for component communication
  - Performance monitoring and warnings
  - Export/import configuration
  - Interactive position queries

## 🚀 Performance Optimizations

### 1. Intelligent Caching
- Pre-calculates all geometric data
- Spatial partitioning for O(1) neighbor lookup
- Automatic cache invalidation only when needed
- Memory usage monitoring and optimization

### 2. Rendering Optimizations
- **Viewport Culling**: Only renders visible elements
- **Level of Detail**: Simplified rendering for distant objects
- **Batch Rendering**: Groups similar draw calls
- **Layer System**: Selective rendering of different elements
- **Frame Rate Monitoring**: Automatic performance adjustments

### 3. Mathematical Optimizations
- Trigonometric value caching
- Distance squared comparisons (avoids sqrt)
- Efficient spatial grid for neighbor searches
- Optimized rotation calculations

## 📊 Configuration System

### Grid Properties
```gdscript
# Grid dimensions
grid_width: int = 25
grid_height: int = 18

# Hexagon properties
hex_size: float = 35.0
hex_color: Color = Color.WHITE
border_color: Color = Color.BLACK
border_width: float = 2.0

# Star properties
dot_radius: float = 6.0
dot_color: Color = Color.WHITE
dot_star_size: float = 3.0

# Diamond properties
diamond_width: float = 35.0
diamond_height: float = 60.0
diamond_color: Color = Color.GREEN

# Global transformation
global_rotation_degrees: float = 30.0

# Performance settings
enable_culling: bool = true
culling_margin: float = 100.0
max_cache_size: int = 10000
```

### Color Distribution
Diamond colors are distributed according to specified ratios:
- **Light Green (00FF00)**: 1/3 of all diamonds
- **Dark Green (007E00)**: 1/6 of all diamonds
- **Cyan (00FFFF)**: 1/6 of all diamonds
- **Gray (666666)**: 1/6 of all diamonds

## 🎮 Usage Examples

### Basic Setup
```gdscript
# Create and configure grid
var hex_grid = HexGridV2.new()
hex_grid.grid_width = 30
hex_grid.grid_height = 20
hex_grid.hex_size = 40.0

# Add to scene
add_child(hex_grid)
```

### Advanced Configuration
```gdscript
# Export current configuration
var config_data = hex_grid.export_config()

# Modify configuration
config_data["grid_width"] = 50
config_data["enable_culling"] = true

# Import modified configuration
hex_grid.import_config(config_data)
```

### Interactive Queries
```gdscript
# Get hexagon at mouse position
var mouse_pos = get_global_mouse_position()
var hex_index = hex_grid.get_hexagon_at_position(mouse_pos)

# Get dot at position
var dot_index = hex_grid.get_dot_at_position(mouse_pos)
```

### Performance Monitoring
```gdscript
# Get comprehensive statistics
var stats = hex_grid.get_grid_stats()
print("Total hexagons: ", stats.total_hexagons)
print("Cache hit ratio: ", stats.cache_stats.hit_ratio)
print("Render time: ", stats.render_stats.last_render_time_ms)

# Monitor performance warnings
hex_grid.performance_warning.connect(_on_performance_warning)

func _on_performance_warning(message: String):
    print("Performance issue: ", message)
```

### Layer Control
```gdscript
# Control rendering layers
hex_grid.set_layer_visibility(HexGridRenderer.RenderLayer.HEXAGONS, false)
hex_grid.set_layer_visibility(HexGridRenderer.RenderLayer.DEBUG, true)
```

## 📈 Performance Metrics

The system provides comprehensive performance tracking:

### Cache Statistics
- Cache hit/miss ratios
- Memory usage in bytes
- Rebuild duration
- Total cached elements

### Rendering Statistics
- Elements rendered per frame
- Culled elements count
- Total draw calls
- Frame time in milliseconds

### Automatic Optimizations
- LOD activation based on distance
- Element count reduction under load
- Cache size optimization
- Culling threshold adjustments

## 🔧 Development Guidelines

### Adding New Features
1. **Configuration**: Add new properties to `HexGridConfig`
2. **Geometry**: Implement calculations in `HexGridGeometry`
3. **Caching**: Update cache invalidation in `HexGridCache`
4. **Rendering**: Add rendering logic to `HexGridRenderer`
5. **Integration**: Expose API in `HexGridV2`

### Performance Considerations
- Always use cached data when possible
- Implement culling for new visual elements
- Consider LOD for complex geometry
- Monitor memory usage for large grids
- Use spatial partitioning for position queries

### Testing
- Test with various grid sizes (1x1 to 200x200)
- Verify performance with large grids (>10,000 hexagons)
- Test configuration serialization/deserialization
- Validate culling accuracy
- Check memory usage under stress

## 🐛 Troubleshooting

### Common Issues

#### Performance Problems
- **Symptom**: Low frame rate with large grids
- **Solution**: Enable culling, reduce grid size, or enable LOD

#### Memory Usage
- **Symptom**: High memory consumption
- **Solution**: Reduce `max_cache_size` or optimize cache

#### Visual Artifacts
- **Symptom**: Missing or incorrect rendering
- **Solution**: Check culling settings and viewport configuration

#### Cache Issues
- **Symptom**: Outdated visual data
- **Solution**: Force cache rebuild with `cache.build_cache(true)`

### Debug Information
Enable debug rendering to visualize:
- Viewport culling bounds
- Performance statistics
- Cache status
- Rendering layers

```gdscript
hex_grid.show_debug_info = true
```

## 🔮 Future Enhancements

### Planned Features
1. **Interactive System**: Click handling and selection
2. **Animation System**: Smooth transitions and effects
3. **Pathfinding**: A* algorithm for hexagonal grids
4. **Serialization**: Save/load grid states
5. **Networking**: Multi-player grid synchronization

### Performance Improvements
1. **GPU Rendering**: Shader-based rendering for massive grids
2. **Streaming**: Dynamic loading/unloading of grid sections
3. **Compression**: Compressed cache storage
4. **Threading**: Background cache building

## 📝 Version History

### v2.0 (Current)
- Complete architectural refactor
- Modular component system
- Intelligent caching
- Performance optimizations
- Comprehensive documentation

### v1.0 (Legacy)
- Basic hexagonal grid implementation
- Monolithic architecture
- Manual cache management
- Limited performance optimizations

## 🤝 Contributing

When contributing to this project:
1. Follow the modular architecture
2. Add comprehensive documentation
3. Include performance considerations
4. Test with various grid sizes
5. Update this README for significant changes

## 📄 License

This project is part of the "Vagabonds & Valleys" game by V&V Game Studio.