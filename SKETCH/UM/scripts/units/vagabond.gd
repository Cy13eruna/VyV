## Vagabond Unit
## 
## Unidade básica que vaga pelo mundo pelas estrelas
## Estados: BEM/MAL, movimento 1 estrela por turno
##
## @author: V&V Game Studio
## @version: 1.0 - UNIT SYSTEM

extends Node2D
class_name Vagabond

## Signals para comunicação
signal unit_moved(from_position: Vector2, to_position: Vector2)
signal unit_state_changed(new_state: UnitState)
signal unit_destroyed()

## Estados da unidade
enum UnitState { BEM, MAL }

## Atributos core
var estado: UnitState = UnitState.BEM : set = set_estado
var dominio_origem: int = -1
var habilidades: Array[String] = []

## Posicionamento
var current_star_position: Vector2
var target_star_position: Vector2
var is_moving: bool = false

## Visual properties
var unit_color: Color = Color.WHITE
var mal_color: Color = Color.RED
var unit_radius: float = 8.0
var particle_system: GPUParticles2D

## Movement properties
var movement_speed: float = 200.0
var moves_per_turn: int = 1
var moves_used_this_turn: int = 0

## References
var hex_grid_ref
var unit_manager_ref

## Initialize vagabond
func _ready() -> void:
	_setup_visual_effects()
	_update_visual_state()
	print("Vagabond created at %s, estado: %s" % [current_star_position, UnitState.keys()[estado]])

## Setup visual effects for MAL state
func _setup_visual_effects() -> void:
	# Create particle system for MAL state
	particle_system = GPUParticles2D.new()
	add_child(particle_system)
	
	# Configure dark particles for MAL state
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 50.0
	material.gravity = Vector3(0, 98, 0)
	material.scale_min = 0.5
	material.scale_max = 1.5
	material.color = Color(0.2, 0.1, 0.1, 0.8)  # Dark particles
	
	particle_system.process_material = material
	particle_system.texture = preload("res://icon.svg")  # Fallback texture
	particle_system.amount = 50
	particle_system.lifetime = 2.0
	particle_system.emitting = false

## Set unit state with visual updates
func set_estado(new_state: UnitState) -> void:
	if estado != new_state:
		var old_state = estado
		estado = new_state
		_update_visual_state()
		unit_state_changed.emit(new_state)
		print("Vagabond state changed: %s -> %s" % [UnitState.keys()[old_state], UnitState.keys()[new_state]])

## Update visual representation based on state
func _update_visual_state() -> void:
	match estado:
		UnitState.BEM:
			modulate = unit_color
			if particle_system:
				particle_system.emitting = false
		UnitState.MAL:
			modulate = mal_color
			if particle_system:
				particle_system.emitting = true

## Initialize unit at specific position
func initialize_at_position(star_pos: Vector2, origin_domain: int = -1) -> void:
	current_star_position = star_pos
	target_star_position = star_pos
	global_position = star_pos
	dominio_origem = origin_domain
	moves_used_this_turn = 0

## Check if unit can move to target position
func can_move_to(target_pos: Vector2) -> bool:
	if is_moving:
		return false
	
	if moves_used_this_turn >= moves_per_turn:
		return false
	
	# Check if target is adjacent star (basic validation)
	var distance = current_star_position.distance_to(target_pos)
	var max_move_distance = 100.0  # Adjust based on grid spacing
	
	return distance <= max_move_distance

## Move unit to target position
func move_to(target_pos: Vector2) -> bool:
	if not can_move_to(target_pos):
		return false
	
	var old_position = current_star_position
	target_star_position = target_pos
	is_moving = true
	moves_used_this_turn += 1
	
	# Create smooth movement tween
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, movement_speed / 100.0)
	tween.tween_callback(_on_movement_completed.bind(old_position, target_pos))
	
	return true

## Handle movement completion
func _on_movement_completed(from_pos: Vector2, to_pos: Vector2) -> void:
	current_star_position = to_pos
	is_moving = false
	unit_moved.emit(from_pos, to_pos)
	print("Vagabond moved from %s to %s" % [from_pos, to_pos])

## Reset moves for new turn
func reset_turn() -> void:
	moves_used_this_turn = 0

## Add ability to unit
func add_ability(ability_name: String) -> void:
	if not habilidades.has(ability_name):
		habilidades.append(ability_name)
		print("Vagabond gained ability: %s" % ability_name)

## Check if unit has specific ability
func has_ability(ability_name: String) -> bool:
	return habilidades.has(ability_name)

## Get unit info for UI/debug
func get_unit_info() -> Dictionary:
	return {
		"type": "Vagabond",
		"estado": UnitState.keys()[estado],
		"position": current_star_position,
		"dominio_origem": dominio_origem,
		"habilidades": habilidades,
		"moves_remaining": moves_per_turn - moves_used_this_turn,
		"is_moving": is_moving
	}

## Handle unit being attacked (future implementation)
func receive_attack() -> void:
	match estado:
		UnitState.BEM:
			set_estado(UnitState.MAL)
		UnitState.MAL:
			destroy_unit()

## Destroy unit
func destroy_unit() -> void:
	unit_destroyed.emit()
	print("Vagabond destroyed at %s" % current_star_position)
	queue_free()

## Draw unit representation
func _draw() -> void:
	# Draw main unit circle
	var color = unit_color if estado == UnitState.BEM else mal_color
	draw_circle(Vector2.ZERO, unit_radius, color)
	
	# Draw border
	draw_arc(Vector2.ZERO, unit_radius, 0, TAU, 32, Color.BLACK, 2.0)
	
	# Draw state indicator
	if estado == UnitState.MAL:
		# Draw X for MAL state
		var x_size = unit_radius * 0.6
		draw_line(Vector2(-x_size, -x_size), Vector2(x_size, x_size), Color.BLACK, 3.0)
		draw_line(Vector2(-x_size, x_size), Vector2(x_size, -x_size), Color.BLACK, 3.0)

## Handle input for unit selection/interaction
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Vagabond clicked: %s" % get_unit_info())

## Clean up on exit
func _exit_tree() -> void:
	if particle_system:
		particle_system.queue_free()