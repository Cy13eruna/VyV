# ⏭️ SKIP TURN BUTTON
# Purpose: UI component for skipping turns
# Layer: Presentation/UI
# Dependencies: None (pure UI)

extends Button

signal skip_turn_requested()

func _ready():
	text = "Skip Turn"
	custom_minimum_size = Vector2(100, 40)
	position = Vector2(900, 50)
	pressed.connect(_on_pressed)

func _on_pressed():
	skip_turn_requested.emit()

func update_for_player(player: Player):
	if player:
		modulate = player.color
	else:
		modulate = Color.WHITE