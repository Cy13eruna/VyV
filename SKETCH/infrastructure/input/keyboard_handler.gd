# ⌨️ KEYBOARD HANDLER
# Purpose: Handle keyboard input events
# Layer: Infrastructure/Input
# Dependencies: GameConstants only

class_name KeyboardHandler
extends RefCounted

signal fog_toggle_requested()
signal skip_turn_requested()

func handle_key_press(event: InputEventKey) -> void:
	if not event.pressed:
		return
	
	match event.keycode:
		GameConstants.FOG_TOGGLE_KEY:
			fog_toggle_requested.emit()
		KEY_ENTER, KEY_KP_ENTER:
			skip_turn_requested.emit()

func handle_input_event(event: InputEvent) -> void:
	if event is InputEventKey:
		handle_key_press(event)