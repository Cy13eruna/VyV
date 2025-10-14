# 🎭 GAME DIALOG STRINGS - COMPLETE CONTROL CENTER
# Purpose: Centralized control for ALL dialog strings, styles, and formatting
# Layer: Presentation Constants
# 
# USAGE: Import this file and use the constants for all dialog text
# CONTROL: Change any string here to update it throughout the entire game

extends RefCounted
class_name GameDialogStrings

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 VISUAL STYLE CONTROLS - MASTER SETTINGS
# ═══════════════════════════════════════════════════════════════════════════════

# BACKGROUND COLORS (RGBA values 0.0 to 1.0)
const DIALOG_BG_COLOR = Color(1.0, 1.0, 1.0, 1.0)  # White background
const DIALOG_BORDER_COLOR = Color(0.0, 0.0, 0.0, 1.0)  # Black border

# BORDER AND CORNER SETTINGS (pixels)
const DIALOG_BORDER_WIDTH = 2  # Border thickness
const DIALOG_CORNER_RADIUS = 8  # Corner roundness (0 = sharp)

# TEXT COLORS (RGBA values 0.0 to 1.0)
const DIALOG_TEXT_COLOR = Color(0.0, 0.0, 0.0, 1.0)  # Black text
const DIALOG_TITLE_COLOR = Color(0.0, 0.0, 0.0, 1.0)  # Black title
const DIALOG_SUBTITLE_COLOR = Color(0.4, 0.4, 0.4, 1.0)  # Gray subtitle

# FONT SIZES (pixels)
const DIALOG_FONT_SIZE = 16      # Main text
const DIALOG_TITLE_FONT_SIZE = 20  # Title text
const DIALOG_SUBTITLE_FONT_SIZE = 14  # Subtitle text

# DIALOG SIZING (screen percentage and pixel limits)
const DIALOG_SIZE_RATIO = Vector2(0.4, 0.3)  # 40% width, 30% height
const DIALOG_MIN_SIZE = Vector2(300, 200)
const DIALOG_MAX_SIZE = Vector2(600, 400)

# SPACING AND MARGINS (pixels)
const BUTTON_SPACING = 20  # Space between buttons
const BUTTON_MARGIN = 20   # Margin around buttons
const SUBTITLE_SPACING = 40  # Space for subtitle area

# VISUAL EFFECTS
const DIALOG_ANTI_ALIASING = true
const DIALOG_OPACITY = 1.0

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 ACTION DIALOG STRINGS
# ═══════════════════════════════════════════════════════════════════════════════

# ACTION SELECTION DIALOG
const ACTION_SELECTION_TITLE = "What %s are going to do?"
const ACTION_SELECTION_SUBTITLE = "Choose an action:"
const ACTION_SELECTION_TEXT = "Choose an action:"

# ACTION DISPLAY NAMES (with emojis)
const ACTION_MOVE_DISPLAY = "👣\nWander"
const ACTION_SETTLE_DISPLAY = "🚩\nSettle"
const ACTION_ATTACK_DISPLAY = "🗡\nFight"
const ACTION_TRAIN_DISPLAY = "📚\nTrain"
const ACTION_HEAL_DISPLAY = "♥\nHeal"

# ═══════════════════════════════════════════════════════════════════════════════
# 🚫 ERROR AND RESTRICTION DIALOGS
# ═══════════════════════════════════════════════════════════════════════════════

# UNIT CANNOT ACT
const UNIT_CANNOT_ACT_TITLE = "Unit Cannot Act"
const UNIT_CANNOT_ACT_SUBTITLE = "Action Restriction"
const UNIT_CANNOT_ACT_NO_ACTIONS = "This unit has no actions remaining this turn."
const UNIT_CANNOT_ACT_UNKNOWN = "This unit cannot act for an unknown reason."

# INSUFFICIENT POWER
const INSUFFICIENT_POWER_TITLE = "Insufficient Power"
const INSUFFICIENT_POWER_SUBTITLE = "Resource Limitation"
const INSUFFICIENT_POWER_TEXT = "You have %d ⭐ power remaining. 🚶🏻‍♀️ Movement requires power."

# ═══════════════════════════════════════════════════════════════════════════════
# 📚 TRAINING DIALOG STRINGS
# ═══════════════════════════════════════════════════════════════════════════════

# TRAINING SELECTION
const TRAINING_SELECTION_TITLE = "Choose Training"
const TRAINING_SELECTION_SUBTITLE = "Unit Development"
const TRAINING_SELECTION_TEXT = "Select a training for %s:"

# TRAINING BUTTON FORMAT
const TRAINING_BUTTON_FORMAT = "%s (Cost: %d⭐)"

# TRAINING TYPES
const TRAINING_FIGHTER_NAME = "Fighter Training"
const TRAINING_HEALER_NAME = "Healer Training"

# ═══════════════════════════════════════════════════════════════════════════════
# 🚩 SETTLEMENT DIALOG STRINGS
# ═══════════════════════════════════════════════════════════════════════════════

# SETTLEMENT CONFIRMATION
const SETTLEMENT_TITLE = "What %s are going to do?"
const SETTLEMENT_SUBTITLE = "Domain Establishment"
const SETTLEMENT_TEXT = "Sacrifice this unit to settle a new domain here?\\n\\nThis action will cost 1 power."
const SETTLEMENT_BUTTON = "SETTLE"

# ═══════════════════════════════════════════════════════════════════════════════
# 🎮 UI INTERFACE STRINGS
# ═══════════════════════════════════════════════════════════════════════════════

# GAME OVER SCREEN
const VICTORY_TITLE = "🏆 VICTORY! 🏆"
const VICTORY_SUBTITLE = "Game Complete"
const VICTORY_WINNER_FORMAT = "Winner: %s"
const VICTORY_QUIT_INSTRUCTION = "Press ESC to quit"

# POWER INDICATOR
const POWER_INDICATOR_FORMAT = "%d ⭐"

# BUTTON LABELS
const BUTTON_SKIP_TURN = "Skip Turn"
const BUTTON_NEW_GAME = "New Game"
const BUTTON_START = "START"
const BUTTON_OK = "OK"

# ═══════════════════════════════════════════════════════════════════════════════
# 📖 CONTROL INSTRUCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

const CONTROLS_BASIC = "🎮 CONTROLS: Click unit → Click position | SPACE: Fog | ENTER: Skip | F1: Debug"
const CONTROLS_CAMERA = "📷 CAMERA: Mouse wheel: Zoom | Right/Middle drag: Pan | +/-: Zoom | 0: Reset | Home: Center"
const CONTROLS_OBJECTIVE = "🏆 OBJECTIVE: Eliminate all enemy units to win! | 🔍 F9: Test | 🔎 F10: Detail | 🔧 F11: Debug"

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 DIALOG STYLING FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Apply complete dialog styling with subtitle support
static func apply_dialog_style(dialog: AcceptDialog):
	# Create style box with master settings
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = DIALOG_BG_COLOR
	style_box.border_color = DIALOG_BORDER_COLOR
	
	# Apply border width to all sides
	style_box.border_width_left = DIALOG_BORDER_WIDTH
	style_box.border_width_right = DIALOG_BORDER_WIDTH
	style_box.border_width_top = DIALOG_BORDER_WIDTH
	style_box.border_width_bottom = DIALOG_BORDER_WIDTH
	
	# Apply corner radius to all corners
	style_box.corner_radius_top_left = DIALOG_CORNER_RADIUS
	style_box.corner_radius_top_right = DIALOG_CORNER_RADIUS
	style_box.corner_radius_bottom_left = DIALOG_CORNER_RADIUS
	style_box.corner_radius_bottom_right = DIALOG_CORNER_RADIUS
	
	style_box.draw_center = true
	style_box.anti_aliasing = DIALOG_ANTI_ALIASING
	
	# Apply the style
	dialog.add_theme_stylebox_override("panel", style_box)
	
	# Apply text colors
	dialog.add_theme_color_override("font_color", DIALOG_TEXT_COLOR)
	dialog.add_theme_color_override("title_color", DIALOG_TITLE_COLOR)
	
	# Apply font sizes
	dialog.add_theme_font_size_override("font_size", DIALOG_FONT_SIZE)
	dialog.add_theme_font_size_override("title_font_size", DIALOG_TITLE_FONT_SIZE)

# Center dialog on screen with consistent sizing
static func center_dialog(dialog: AcceptDialog):
	# Get screen size
	var screen_size = DisplayServer.screen_get_size()
	
	# Calculate dialog size based on screen ratio
	var dialog_size = Vector2(
		max(DIALOG_MIN_SIZE.x, min(DIALOG_MAX_SIZE.x, screen_size.x * DIALOG_SIZE_RATIO.x)),
		max(DIALOG_MIN_SIZE.y, min(DIALOG_MAX_SIZE.y, screen_size.y * DIALOG_SIZE_RATIO.y))
	)
	
	# Set dialog size
	dialog.size = dialog_size
	
	# Center dialog
	dialog.popup_centered()

# Apply button styling (uses Godot defaults)
static func apply_button_style(button: Button):
	# No custom styling - use Godot default appearance
	pass

# Create subtitle label with proper styling
static func create_subtitle_label(subtitle_text: String) -> Label:
	var subtitle_label = Label.new()
	subtitle_label.text = subtitle_text
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_color_override("font_color", DIALOG_SUBTITLE_COLOR)
	subtitle_label.add_theme_font_size_override("font_size", DIALOG_SUBTITLE_FONT_SIZE)
	subtitle_label.custom_minimum_size = Vector2(0, SUBTITLE_SPACING)
	return subtitle_label

# Create spacer for subtitle area
static func create_subtitle_spacer() -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, SUBTITLE_SPACING)
	return spacer



# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 DIALOG CREATION HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

# Create a complete dialog with title, subtitle, and text
static func create_styled_dialog(title: String, subtitle: String, text: String) -> AcceptDialog:
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = text
	
	# Apply styling
	apply_dialog_style(dialog)
	
	# Create main container for proper spacing
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", BUTTON_SPACING)
	
	# Add subtitle if provided
	if subtitle != "":
		var subtitle_label = create_subtitle_label(subtitle)
		main_container.add_child(subtitle_label)
	
	# Add spacer after subtitle to ensure proper spacing
	var spacer = create_subtitle_spacer()
	main_container.add_child(spacer)
	
	# Add the main container to dialog
	dialog.add_child(main_container)
	
	return dialog

# Create action selection dialog with subtitle
static func create_action_selection_dialog(unit_name: String) -> AcceptDialog:
	var title = ACTION_SELECTION_TITLE % unit_name
	var subtitle = ACTION_SELECTION_SUBTITLE
	var text = ACTION_SELECTION_TEXT
	
	return create_styled_dialog(title, subtitle, text)

# Create training selection dialog with subtitle
static func create_training_selection_dialog(unit_name: String) -> AcceptDialog:
	var title = TRAINING_SELECTION_TITLE
	var subtitle = TRAINING_SELECTION_SUBTITLE
	var text = TRAINING_SELECTION_TEXT % unit_name
	
	return create_styled_dialog(title, subtitle, text)

# Create settlement confirmation dialog with subtitle
static func create_settlement_dialog(unit_name: String) -> AcceptDialog:
	var title = SETTLEMENT_TITLE % unit_name
	var subtitle = SETTLEMENT_SUBTITLE
	var text = SETTLEMENT_TEXT
	
	return create_styled_dialog(title, subtitle, text)

# Create unit cannot act dialog with subtitle
static func create_unit_cannot_act_dialog(reason: String = "") -> AcceptDialog:
	var title = UNIT_CANNOT_ACT_TITLE
	var subtitle = UNIT_CANNOT_ACT_SUBTITLE
	var text = reason if reason != "" else UNIT_CANNOT_ACT_UNKNOWN
	
	return create_styled_dialog(title, subtitle, text)

# Create insufficient power dialog with subtitle
static func create_insufficient_power_dialog(power_remaining: int) -> AcceptDialog:
	var title = INSUFFICIENT_POWER_TITLE
	var subtitle = INSUFFICIENT_POWER_SUBTITLE
	var text = INSUFFICIENT_POWER_TEXT % power_remaining
	
	return create_styled_dialog(title, subtitle, text)

# ═══════════════════════════════════════════════════════════════════════════════
# 📝 USAGE EXAMPLES AND DOCUMENTATION
# ═══════════════════════════════════════════════════════════════════════════════

# EXAMPLE USAGE:
# 
# # Simple dialog creation:
# var dialog = GameDialogStrings.create_action_selection_dialog("Warrior")
# main_node.add_child(dialog)
# GameDialogStrings.center_dialog(dialog)
# 
# # Custom dialog with subtitle:
# var dialog = GameDialogStrings.create_styled_dialog(
#     "Custom Title", 
#     "Custom Subtitle", 
#     "Custom message text"
# )
# 
# # Using string constants:
# button.text = GameDialogStrings.BUTTON_OK
# label.text = GameDialogStrings.VICTORY_TITLE
# 
# # Formatting strings:
# var power_text = GameDialogStrings.POWER_INDICATOR_FORMAT % total_power
# var winner_text = GameDialogStrings.VICTORY_WINNER_FORMAT % winner_name

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 CUSTOMIZATION GUIDE
# ═══════════════════════════════════════════════════════════════════════════════

# TO CHANGE DIALOG APPEARANCE:
# 1. Modify the style constants at the top of this file
# 2. Colors use RGBA format (Red, Green, Blue, Alpha) from 0.0 to 1.0
# 3. Sizes are in pixels
# 4. All dialogs will automatically use the new settings
#
# TO CHANGE DIALOG TEXT:
# 1. Find the appropriate constant in the sections above
# 2. Change the string value
# 3. Use %s for string formatting and %d for number formatting
# 4. All dialogs using that constant will update automatically
#
# TO ADD NEW DIALOGS:
# 1. Add string constants in the appropriate section
# 2. Create a helper function in the "DIALOG CREATION HELPERS" section
# 3. Use the create_styled_dialog() function for consistency