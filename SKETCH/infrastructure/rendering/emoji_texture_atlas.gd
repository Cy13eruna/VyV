# 🎨 EMOJI TEXTURE ATLAS
# Purpose: Convert emojis to texture atlas for advanced manipulation
# Layer: Infrastructure/Rendering
# Dependencies: None

extends RefCounted

# Texture atlas configuration
const EMOJI_SIZE = 64  # Size of each emoji in the atlas
const ATLAS_WIDTH = 512  # Width of the texture atlas
const ATLAS_HEIGHT = 512  # Height of the texture atlas
const EMOJIS_PER_ROW = ATLAS_WIDTH / EMOJI_SIZE  # 8 emojis per row
const EMOJIS_PER_COLUMN = ATLAS_HEIGHT / EMOJI_SIZE  # 8 emojis per column

# Emoji registry
static var emoji_registry = {}
static var atlas_texture: ImageTexture = null
static var atlas_image: Image = null

# Initialize the emoji texture atlas
static func initialize_atlas() -> void:
	print("[EMOJI_ATLAS] Initializing emoji texture atlas...")
	
	# Create a new image for the atlas
	atlas_image = Image.create(ATLAS_WIDTH, ATLAS_HEIGHT, false, Image.FORMAT_RGBA8)
	atlas_image.fill(Color.TRANSPARENT)
	
	# Register common emojis used in the game
	_register_game_emojis()
	
	# Create texture from image
	atlas_texture = ImageTexture.create_from_image(atlas_image)
	
	print("[EMOJI_ATLAS] Atlas initialized with %d emojis" % emoji_registry.size())

# Register emojis used in the game
static func _register_game_emojis() -> void:
	var emojis_to_register = [
		"🚶🏻‍♀️",  # Unit emoji
		"🌳",      # Forest
		"⛰",       # Mountain  
		"〰",       # Water
		"🏔",       # Field/Plains
		"🔥",       # Fire effect
		"⚡",       # Lightning effect
		"💎"        # Crystal/gem effect
	]
	
	var index = 0
	for emoji in emojis_to_register:
		_register_emoji(emoji, index)
		index += 1

# Register a single emoji in the atlas
static func _register_emoji(emoji: String, index: int) -> void:
	if index >= EMOJIS_PER_ROW * EMOJIS_PER_COLUMN:
		print("[EMOJI_ATLAS] Warning: Atlas full, cannot register emoji: %s" % emoji)
		return
	
	# Calculate position in atlas
	var row = index / EMOJIS_PER_ROW
	var col = index % EMOJIS_PER_ROW
	var x = col * EMOJI_SIZE
	var y = row * EMOJI_SIZE
	
	# Create emoji texture using a temporary canvas
	var emoji_image = _create_emoji_image(emoji)
	
	# Blit emoji image to atlas
	atlas_image.blit_rect(emoji_image, Rect2i(0, 0, EMOJI_SIZE, EMOJI_SIZE), Vector2i(x, y))
	
	# Store emoji info in registry
	emoji_registry[emoji] = {
		"index": index,
		"rect": Rect2(x, y, EMOJI_SIZE, EMOJI_SIZE),
		"uv_rect": Rect2(float(x) / ATLAS_WIDTH, float(y) / ATLAS_HEIGHT, 
						float(EMOJI_SIZE) / ATLAS_WIDTH, float(EMOJI_SIZE) / ATLAS_HEIGHT)
	}
	
	print("[EMOJI_ATLAS] Registered emoji '%s' at index %d (%d, %d)" % [emoji, index, x, y])

# Create an image from emoji text (fallback method)
static func _create_emoji_image(emoji: String) -> Image:
	# Create a temporary image
	var image = Image.create(EMOJI_SIZE, EMOJI_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Note: In a real implementation, you would:
	# 1. Use a font that supports emoji rendering
	# 2. Render the emoji to a texture
	# 3. Extract the image data
	# For now, we'll create a colored square as placeholder
	
	var color = _get_emoji_placeholder_color(emoji)
	var rect = Rect2i(8, 8, EMOJI_SIZE - 16, EMOJI_SIZE - 16)
	image.fill_rect(rect, color)
	
	return image

# Get placeholder color for emoji (temporary solution)
static func _get_emoji_placeholder_color(emoji: String) -> Color:
	match emoji:
		"🚶🏻‍♀️": return Color.BLUE
		"🌳": return Color.GREEN
		"⛰": return Color.GRAY
		"〰": return Color.CYAN
		"🏔": return Color.YELLOW
		"🔥": return Color.RED
		"⚡": return Color.PURPLE
		"💎": return Color.MAGENTA
		_: return Color.WHITE

# Get emoji texture rect from atlas
static func get_emoji_rect(emoji: String) -> Rect2:
	if emoji in emoji_registry:
		return emoji_registry[emoji]["rect"]
	return Rect2()

# Get emoji UV coordinates for shader use
static func get_emoji_uv_rect(emoji: String) -> Rect2:
	if emoji in emoji_registry:
		return emoji_registry[emoji]["uv_rect"]
	return Rect2(0, 0, 1, 1)

# Get the atlas texture
static func get_atlas_texture() -> ImageTexture:
	if atlas_texture == null:
		initialize_atlas()
	return atlas_texture

# Draw emoji from atlas with effects
static func draw_emoji_from_atlas(canvas: CanvasItem, emoji: String, position: Vector2, 
								size: Vector2 = Vector2(32, 32), color: Color = Color.WHITE, 
								flip_horizontal: bool = false, rotation: float = 0.0) -> void:
	
	if atlas_texture == null:
		initialize_atlas()
	
	if not emoji in emoji_registry:
		print("[EMOJI_ATLAS] Warning: Emoji '%s' not found in atlas" % emoji)
		return
	
	var emoji_rect = emoji_registry[emoji]["rect"]
	
	# Create transform for effects
	var transform = Transform2D()
	transform = transform.translated(-size / 2)  # Center origin
	
	if flip_horizontal:
		transform = transform.scaled(Vector2(-1, 1))
	
	if rotation != 0.0:
		transform = transform.rotated(rotation)
	
	transform = transform.translated(position)
	
	# Draw the emoji sprite from atlas
	canvas.draw_set_transform_matrix(transform)
	canvas.draw_texture_rect_region(atlas_texture, Rect2(Vector2.ZERO, size), emoji_rect, color)
	canvas.draw_set_transform_matrix(Transform2D())  # Reset transform

# Draw unit emoji with team color and direction effects
static func draw_unit_emoji(canvas: CanvasItem, unit_id: int, position: Vector2, 
							size: Vector2 = Vector2(32, 32), team_color: Color = Color.WHITE, 
							has_actions: bool = true) -> void:
	
	# Get unit movement direction
	var UnitMovementTracker = load("res://core/value_objects/unit_movement_tracker.gd")
	var should_flip = UnitMovementTracker.should_flip_emoji(unit_id)
	
	# Calculate emoji color based on team color and action state
	var emoji_color = team_color
	if not has_actions:
		# Unit has no actions - blend with white to make it appear "exhausted"
		emoji_color = team_color.lerp(Color.WHITE, 0.7)
	
	# Use the unit emoji (walking woman)
	var unit_emoji = "🚶🏻‍♀️"
	
	# Draw the emoji with effects
	draw_emoji_from_atlas(canvas, unit_emoji, position, size, emoji_color, should_flip)
	
	# Debug: Show direction indicator if debug is enabled
	if _is_debug_enabled():
		var direction_emoji = UnitMovementTracker.get_direction_emoji(unit_id)
		var debug_pos = position + Vector2(size.x * 0.6, -size.y * 0.3)
		var debug_size = size * 0.4
		draw_emoji_from_atlas(canvas, direction_emoji, debug_pos, debug_size, Color.YELLOW)

# Check if debug mode is enabled (simple check)
static func _is_debug_enabled() -> bool:
	# This is a simple way to check debug mode
	# In a real implementation, this could check a global debug flag
	return false  # Set to true for debugging

# Apply team color tint to emoji
static func get_team_colored_emoji_color(base_color: Color, team_color: Color, intensity: float = 0.7) -> Color:
	# Blend the base color with team color
	return base_color.lerp(team_color, intensity)

# Get enhanced team color for unit emoji
static func get_unit_team_color(team_color: Color, has_actions: bool = true, enhancement: float = 0.8) -> Color:
	# Enhance the team color for better visibility
	var enhanced_color = team_color
	
	# Make the color more vibrant
	enhanced_color.s = min(enhanced_color.s * 1.2, 1.0)  # Increase saturation
	enhanced_color.v = min(enhanced_color.v * 1.1, 1.0)  # Increase brightness
	
	if not has_actions:
		# Unit exhausted - blend with white
		enhanced_color = enhanced_color.lerp(Color.WHITE, 0.6)
	
	return enhanced_color

# Check if emoji is registered
static func is_emoji_registered(emoji: String) -> bool:
	return emoji in emoji_registry

# Get all registered emojis
static func get_registered_emojis() -> Array:
	return emoji_registry.keys()

# Update atlas texture (call after modifications)
static func update_atlas_texture() -> void:
	if atlas_texture and atlas_image:
		atlas_texture.update(atlas_image)