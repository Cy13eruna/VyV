# 🏗️ STRUCTURE
# Purpose: Buildable structure entity (replicable for N structures)
# Layer: Core/Entities
# Dependencies: Position, GameConstants

extends RefCounted

var id: int
var owner_id: int
var name: String
var structure_type: int  # 0=Farm, 1=Village, 2=Fortress, etc.
var edge_id: int  # Edge where structure is built
var domain_id: int  # Domain that owns this structure
var construction_progress: int = 0
var is_completed: bool = false
var health: int = 100
var effects: Dictionary = {}  # Structure effects (power generation, defense, etc.)

# Structure types
enum StructureType {
	FARM = 0,      # +1 power generation
	VILLAGE = 1,   # +2 power generation, +1 unit capacity
	FORTRESS = 2,  # +3 defense, blocks movement
	MARKET = 3,    # +1 power, enables trade
	TEMPLE = 4     # +1 power, +1 influence radius
}

func _init(structure_id: int, player_id: int, struct_type: int, target_edge_id: int, target_domain_id: int):
	id = structure_id
	owner_id = player_id
	structure_type = struct_type
	edge_id = target_edge_id
	domain_id = target_domain_id
	name = _get_structure_name(struct_type)
	effects = _get_structure_effects(struct_type)
	
	# Structures start under construction
	construction_progress = 0
	is_completed = false

# Get structure name based on type
func _get_structure_name(struct_type: int) -> String:
	match struct_type:
		StructureType.FARM:
			return "Farm"
		StructureType.VILLAGE:
			return "Village"
		StructureType.FORTRESS:
			return "Fortress"
		StructureType.MARKET:
			return "Market"
		StructureType.TEMPLE:
			return "Temple"
		_:
			return "Structure"

# Get structure effects based on type
func _get_structure_effects(struct_type: int) -> Dictionary:
	match struct_type:
		StructureType.FARM:
			return {"power_generation": 1, "construction_cost": 2, "construction_time": 1}
		StructureType.VILLAGE:
			return {"power_generation": 2, "unit_capacity": 1, "construction_cost": 4, "construction_time": 2}
		StructureType.FORTRESS:
			return {"defense": 3, "blocks_movement": true, "construction_cost": 6, "construction_time": 3}
		StructureType.MARKET:
			return {"power_generation": 1, "enables_trade": true, "construction_cost": 3, "construction_time": 2}
		StructureType.TEMPLE:
			return {"power_generation": 1, "influence_bonus": 1, "construction_cost": 5, "construction_time": 3}
		_:
			return {"construction_cost": 1, "construction_time": 1}

# Advance construction progress
func advance_construction() -> bool:
	if is_completed:
		return false
	
	construction_progress += 1
	var required_time = effects.get("construction_time", 1)
	
	if construction_progress >= required_time:
		is_completed = true
		return true
	
	return false

# Check if structure can be built (cost requirements)
func can_afford_construction(available_power: int) -> bool:
	var cost = effects.get("construction_cost", 1)
	return available_power >= cost

# Get construction cost
func get_construction_cost() -> int:
	return effects.get("construction_cost", 1)

# Get construction time
func get_construction_time() -> int:
	return effects.get("construction_time", 1)

# Check if structure blocks movement
func blocks_movement() -> bool:
	return effects.get("blocks_movement", false)

# Get power generation bonus
func get_power_generation() -> int:
	if is_completed:
		return effects.get("power_generation", 0)
	return 0

# Get defense bonus
func get_defense_bonus() -> int:
	if is_completed:
		return effects.get("defense", 0)
	return 0

# Take damage
func take_damage(damage: int) -> bool:
	health -= damage
	if health <= 0:
		health = 0
		return true  # Structure destroyed
	return false

# Repair structure
func repair(amount: int) -> void:
	health = min(100, health + amount)

# Check if structure is destroyed
func is_destroyed() -> bool:
	return health <= 0

# Get structure status
func get_status() -> String:
	if is_destroyed():
		return "Destroyed"
	elif not is_completed:
		return "Under Construction (%d/%d)" % [construction_progress, get_construction_time()]
	else:
		return "Operational"

# Get structure icon/emoji
func get_icon() -> String:
	match structure_type:
		StructureType.FARM:
			return "🌾"
		StructureType.VILLAGE:
			return "🏘️"
		StructureType.FORTRESS:
			return "🏰"
		StructureType.MARKET:
			return "🏪"
		StructureType.TEMPLE:
			return "⛪"
		_:
			return "🏗️"

# String representation for debugging
func get_string() -> String:
	var status = get_status()
	return "Structure[%d] %s (%s) on edge %d - %s (HP: %d)" % [
		id, name, get_icon(), edge_id, status, health
	]