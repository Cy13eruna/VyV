# 🤖 AI PLAYER
# Purpose: Artificial intelligence for computer players
# Layer: Infrastructure/AI

extends RefCounted

class_name AIPlayer

enum Difficulty {
	EASY,
	MEDIUM,
	HARD,
	EXPERT
}

enum Strategy {
	AGGRESSIVE,
	DEFENSIVE,
	BALANCED,
	ECONOMIC
}

# AI configuration
var player_id: int
var difficulty: Difficulty
var strategy: Strategy
var thinking_time: float = 1.0

# AI state
var evaluation_cache: Dictionary = {}
var last_evaluation: float = 0.0
var move_history: Array = []

# Initialize AI player
func _init(id: int, diff: Difficulty = Difficulty.MEDIUM, strat: Strategy = Strategy.BALANCED):
	player_id = id
	difficulty = diff
	strategy = strat
	
	# Set thinking time based on difficulty
	match difficulty:
		Difficulty.EASY:
			thinking_time = 0.5
		Difficulty.MEDIUM:
			thinking_time = 1.0
		Difficulty.HARD:
			thinking_time = 1.5
		Difficulty.EXPERT:
			thinking_time = 2.0

# Make AI decision for current turn
func make_decision(game_state: Dictionary) -> Dictionary:
	var decision = {
		"type": "none",
		"unit_id": -1,
		"target_position": null,
		"confidence": 0.0
	}
	
	# Evaluate current game state
	var evaluation = _evaluate_game_state(game_state)
	last_evaluation = evaluation
	
	# Get all possible moves for AI player
	var possible_moves = _get_possible_moves(game_state)
	
	if possible_moves.is_empty():
		decision.type = "skip_turn"
		return decision
	
	# Select best move based on strategy and difficulty
	var best_move = _select_best_move(possible_moves, game_state)
	
	if best_move:
		decision.type = "move_unit"
		decision.unit_id = best_move.unit_id
		decision.target_position = best_move.target_position
		decision.confidence = best_move.score
		
		# Add to move history
		move_history.append({
			"turn": game_state.turn_data.turn_number,
			"move": best_move,
			"evaluation": evaluation
		})
	else:
		decision.type = "skip_turn"
	
	return decision

# Evaluate current game state from AI perspective
func _evaluate_game_state(game_state: Dictionary) -> float:
	var score = 0.0
	
	# Unit count advantage
	var ai_units = _count_player_units(player_id, game_state)
	var enemy_units = _count_enemy_units(player_id, game_state)
	score += (ai_units - enemy_units) * 100.0
	
	# Domain control
	var ai_domains = _count_player_domains(player_id, game_state)
	var enemy_domains = _count_enemy_domains(player_id, game_state)
	score += (ai_domains - enemy_domains) * 50.0
	
	# Power advantage
	var ai_power = _get_player_total_power(player_id, game_state)
	var enemy_power = _get_enemy_total_power(player_id, game_state)
	score += (ai_power - enemy_power) * 10.0
	
	# Positional advantage
	score += _evaluate_positions(game_state) * 25.0
	
	# Strategy-specific bonuses
	match strategy:
		Strategy.AGGRESSIVE:
			score += _evaluate_aggressive_position(game_state) * 20.0
		Strategy.DEFENSIVE:
			score += _evaluate_defensive_position(game_state) * 20.0
		Strategy.ECONOMIC:
			score += ai_power * 5.0  # Extra weight on power
	
	return score

# Get all possible moves for AI player
func _get_possible_moves(game_state: Dictionary) -> Array:
	var moves = []
	
	if not (player_id in game_state.players):
		return moves
	
	var player = game_state.players[player_id]
	
	# Check each unit
	for unit_id in player.unit_ids:
		if unit_id in game_state.units:
			var unit = game_state.units[unit_id]
			if unit.can_move():
				# Get valid movement targets
				var targets = _get_unit_movement_targets(unit, game_state)
				
				for target in targets:
					moves.append({
						"unit_id": unit_id,
						"target_position": target,
						"score": 0.0
					})
	
	return moves

# Select best move using minimax or heuristics
func _select_best_move(possible_moves: Array, game_state: Dictionary):
	if possible_moves.is_empty():
		return null
	
	var best_move = null
	var best_score = -INF
	
	for move in possible_moves:
		var score = _evaluate_move(move, game_state)
		move.score = score
		
		if score > best_score:
			best_score = score
			best_move = move
	
	# Add some randomness for lower difficulties
	if difficulty == Difficulty.EASY:
		# 30% chance to pick a random move instead
		if randf() < 0.3 and possible_moves.size() > 1:
			return possible_moves[randi() % possible_moves.size()]
	elif difficulty == Difficulty.MEDIUM:
		# 15% chance for suboptimal move
		if randf() < 0.15 and possible_moves.size() > 1:
			possible_moves.sort_custom(func(a, b): return a.score > b.score)
			var top_moves = possible_moves.slice(0, min(3, possible_moves.size()))
			return top_moves[randi() % top_moves.size()]
	
	return best_move

# Evaluate a specific move
func _evaluate_move(move: Dictionary, game_state: Dictionary) -> float:
	var score = 0.0
	var unit = game_state.units[move.unit_id]
	var target_pos = move.target_position
	
	# Distance to enemies (aggressive strategy likes closer)
	var enemy_distance = _get_distance_to_nearest_enemy(target_pos, game_state)
	if strategy == Strategy.AGGRESSIVE:
		score += (10.0 - enemy_distance) * 5.0  # Closer is better
	elif strategy == Strategy.DEFENSIVE:
		score += enemy_distance * 3.0  # Farther is better
	
	# Distance to own domains (defensive likes closer to home)
	var domain_distance = _get_distance_to_nearest_own_domain(target_pos, game_state)
	if strategy == Strategy.DEFENSIVE:
		score += (5.0 - domain_distance) * 4.0
	
	# Control of strategic positions
	if _is_strategic_position(target_pos, game_state):
		score += 15.0
	
	# Avoid clustering units
	var unit_density = _get_unit_density_at_position(target_pos, game_state)
	score -= unit_density * 5.0
	
	return score

# Helper functions for evaluation
func _count_player_units(pid: int, game_state: Dictionary) -> int:
	var count = 0
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.owner_id == pid:
			count += 1
	return count

func _count_enemy_units(pid: int, game_state: Dictionary) -> int:
	var count = 0
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.owner_id != pid:
			count += 1
	return count

func _count_player_domains(pid: int, game_state: Dictionary) -> int:
	var count = 0
	if "domains" in game_state:
		for domain_id in game_state.domains:
			var domain = game_state.domains[domain_id]
			if domain.owner_id == pid:
				count += 1
	return count

func _count_enemy_domains(pid: int, game_state: Dictionary) -> int:
	var count = 0
	if "domains" in game_state:
		for domain_id in game_state.domains:
			var domain = game_state.domains[domain_id]
			if domain.owner_id != pid:
				count += 1
	return count

func _get_player_total_power(pid: int, game_state: Dictionary) -> int:
	var total = 0
	if "domains" in game_state:
		for domain_id in game_state.domains:
			var domain = game_state.domains[domain_id]
			if domain.owner_id == pid:
				total += domain.power
	return total

func _get_enemy_total_power(pid: int, game_state: Dictionary) -> int:
	var total = 0
	if "domains" in game_state:
		for domain_id in game_state.domains:
			var domain = game_state.domains[domain_id]
			if domain.owner_id != pid:
				total += domain.power
	return total

func _evaluate_positions(game_state: Dictionary) -> float:
	# Placeholder for positional evaluation
	return 0.0

func _evaluate_aggressive_position(game_state: Dictionary) -> float:
	# Bonus for being close to enemies
	return 0.0

func _evaluate_defensive_position(game_state: Dictionary) -> float:
	# Bonus for defensive positioning
	return 0.0

func _get_unit_movement_targets(unit, game_state: Dictionary) -> Array:
	# Use MovementService to get valid targets
	var MovementService = load("res://application/services/movement_service_clean.gd")
	return MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units)

func _get_distance_to_nearest_enemy(position, game_state: Dictionary) -> float:
	var min_distance = INF
	
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.owner_id != player_id:
			var distance = position.distance_to(unit.position)
			min_distance = min(min_distance, distance)
	
	return min_distance

func _get_distance_to_nearest_own_domain(position, game_state: Dictionary) -> float:
	var min_distance = INF
	
	if "domains" in game_state:
		for domain_id in game_state.domains:
			var domain = game_state.domains[domain_id]
			if domain.owner_id == player_id:
				var distance = position.distance_to(domain.center_position)
				min_distance = min(min_distance, distance)
	
	return min_distance

func _is_strategic_position(position, game_state: Dictionary) -> bool:
	# Check if position is near corners or center
	if "grid" in game_state:
		for point_id in game_state.grid.points:
			var point = game_state.grid.points[point_id]
			if point.is_corner and position.distance_to(point.position) <= 1:
				return true
	
	return false

func _get_unit_density_at_position(position, game_state: Dictionary) -> int:
	var density = 0
	
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.owner_id == player_id and position.distance_to(unit.position) <= 2:
			density += 1
	
	return density

# Get AI statistics
func get_ai_stats() -> Dictionary:
	return {
		"player_id": player_id,
		"difficulty": Difficulty.keys()[difficulty],
		"strategy": Strategy.keys()[strategy],
		"thinking_time": thinking_time,
		"last_evaluation": last_evaluation,
		"moves_made": move_history.size()
	}