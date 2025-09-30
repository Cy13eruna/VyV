# 🎮 INPUT MANAGER
# Purpose: Coordinate all input handling
# Layer: Infrastructure/Input
# Dependencies: Input handlers only

class_name InputManager
extends RefCounted

signal point_clicked(point_id: int)
signal point_hovered(point_id: int)
signal point_unhovered(point_id: int)
signal fog_toggle_requested()
signal skip_turn_requested()

var mouse_handler: MouseHandler
var keyboard_handler: KeyboardHandler

func _init():
	mouse_handler = MouseHandler.new()
	keyboard_handler = KeyboardHandler.new()
	
	# Connect signals
	mouse_handler.point_clicked.connect(_on_point_clicked)
	mouse_handler.point_hovered.connect(_on_point_hovered)
	mouse_handler.point_unhovered.connect(_on_point_unhovered)
	
	keyboard_handler.fog_toggle_requested.connect(_on_fog_toggle_requested)
	keyboard_handler.skip_turn_requested.connect(_on_skip_turn_requested)

func handle_input_event(event: InputEvent, grid_data: Dictionary) -> void:
	if event is InputEventMouseMotion:
		mouse_handler.handle_mouse_motion(event.position, grid_data)
	elif event is InputEventMouseButton and event.pressed:
		mouse_handler.handle_mouse_click(event.position, grid_data)
	elif event is InputEventKey:
		keyboard_handler.handle_input_event(event)

func get_hovered_point() -> int:
	return mouse_handler.get_hovered_point()

func clear_hover() -> void:
	mouse_handler.clear_hover()

func _on_point_clicked(point_id: int) -> void:
	point_clicked.emit(point_id)

func _on_point_hovered(point_id: int) -> void:
	point_hovered.emit(point_id)

func _on_point_unhovered(point_id: int) -> void:
	point_unhovered.emit(point_id)

func _on_fog_toggle_requested() -> void:
	fog_toggle_requested.emit()

func _on_skip_turn_requested() -> void:
	skip_turn_requested.emit()