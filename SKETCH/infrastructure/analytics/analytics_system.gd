# 📊 ANALYTICS SYSTEM
# Purpose: Game analytics, metrics collection and analysis
# Layer: Infrastructure/Analytics

extends RefCounted

class_name AnalyticsSystem

# Event types
enum EventType {
	GAME_START,
	GAME_END,
	TURN_START,
	TURN_END,
	UNIT_MOVE,
	UNIT_ATTACK,
	UNIT_DEATH,
	TERRITORY_CAPTURE,
	RESOURCE_GAIN,
	RESOURCE_SPEND,
	PLAYER_ACTION,
	AI_DECISION,
	PERFORMANCE_SAMPLE
}

# Analytics event structure
class AnalyticsEvent:
	var event_id: String
	var event_type: EventType
	var timestamp: float
	var session_id: String
	var player_id: int
	var data: Dictionary
	var game_state_snapshot: Dictionary
	
	func _init(type: EventType, pid: int, event_data: Dictionary = {}):
		event_type = type
		player_id = pid
		data = event_data
		timestamp = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
		event_id = "EVT_%d_%d_%d" % [type, timestamp, randi() % 1000]
	
	func to_dict() -> Dictionary:
		return {
			"event_id": event_id,
			"event_type": EventType.keys()[event_type],
			"timestamp": timestamp,
			"session_id": session_id,
			"player_id": player_id,
			"data": data,
			"game_state": game_state_snapshot
		}

# Game session data
class GameSession:
	var session_id: String
	var start_time: float
	var end_time: float
	var duration: float
	var player_count: int
	var winner_id: int = -1
	var total_turns: int = 0
	var events: Array = []
	var final_stats: Dictionary = {}
	
	func _init(players: int):
		session_id = "SESSION_%d_%d" % [Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second, randi() % 1000]
		start_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
		player_count = players
	
	func end_session(winner: int = -1) -> void:
		end_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
		duration = end_time - start_time
		winner_id = winner

# Analytics state
var current_session: GameSession
var all_sessions: Array = []
var events_buffer: Array = []
var max_buffer_size: int = 1000
var analytics_enabled: bool = true

# Performance metrics
var performance_metrics: Dictionary = {
	"avg_fps": 0.0,
	"min_fps": 999.0,
	"max_fps": 0.0,
	"avg_frame_time": 0.0,
	"memory_usage": 0.0,
	"frame_drops": 0
}

# Game balance metrics
var balance_metrics: Dictionary = {
	"unit_win_rates": {},
	"terrain_usage": {},
	"average_game_length": 0.0,
	"player_action_frequency": {},
	"resource_efficiency": {}
}

# Player behavior metrics
var player_metrics: Dictionary = {
	"actions_per_turn": {},
	"decision_time": {},
	"strategy_patterns": {},
	"error_rate": {}
}

# Singleton instance
static var instance: AnalyticsSystem

# Initialize analytics system
func _init():
	if instance == null:
		instance = self
	
	print("📊 Analytics System initialized")

# Get singleton instance
static func get_instance():
	if instance == null:
		instance = AnalyticsSystem.new()
	return instance

# Session management
func start_game_session(player_count: int) -> void:
	if current_session:
		end_game_session()
	
	current_session = GameSession.new(player_count)
	track_event(EventType.GAME_START, -1, {"player_count": player_count})
	
	print("📊 Game session started: %s" % current_session.session_id)

func end_game_session(winner_id: int = -1) -> void:
	if not current_session:
		return
	
	current_session.end_session(winner_id)
	track_event(EventType.GAME_END, winner_id, {
		"duration": current_session.duration,
		"total_turns": current_session.total_turns,
		"winner": winner_id
	})
	
	all_sessions.append(current_session)
	print("📊 Game session ended: %s (Duration: %.1fs)" % [current_session.session_id, current_session.duration])
	
	current_session = null

# Event tracking
func track_event(event_type: EventType, player_id: int, data: Dictionary = {}, game_state: Dictionary = {}) -> void:
	if not analytics_enabled:
		return
	
	var event = AnalyticsEvent.new(event_type, player_id, data)
	
	if current_session:
		event.session_id = current_session.session_id
		current_session.events.append(event)
	
	# Store lightweight game state snapshot for important events
	if event_type in [EventType.GAME_START, EventType.GAME_END, EventType.TURN_END]:
		event.game_state_snapshot = _create_state_snapshot(game_state)
	
	events_buffer.append(event)
	
	# Trim buffer if too large
	if events_buffer.size() > max_buffer_size:
		events_buffer.pop_front()
	
	# Update metrics based on event
	_update_metrics(event)

# Convenience tracking methods
func track_unit_move(player_id: int, unit_id: int, from_pos, to_pos, game_state: Dictionary) -> void:
	track_event(EventType.UNIT_MOVE, player_id, {
		"unit_id": unit_id,
		"from": {"q": from_pos.q, "r": from_pos.r},
		"to": {"q": to_pos.q, "r": to_pos.r}
	}, game_state)

func track_unit_attack(attacker_id: int, defender_id: int, damage: int, player_id: int) -> void:
	track_event(EventType.UNIT_ATTACK, player_id, {
		"attacker_id": attacker_id,
		"defender_id": defender_id,
		"damage": damage
	})

func track_unit_death(unit_id: int, killer_id: int, player_id: int) -> void:
	track_event(EventType.UNIT_DEATH, player_id, {
		"unit_id": unit_id,
		"killer_id": killer_id
	})

func track_turn_start(player_id: int, turn_number: int, game_state: Dictionary) -> void:
	if current_session:
		current_session.total_turns = turn_number
	
	track_event(EventType.TURN_START, player_id, {
		"turn_number": turn_number
	}, game_state)

func track_turn_end(player_id: int, turn_number: int, actions_taken: int, game_state: Dictionary) -> void:
	track_event(EventType.TURN_END, player_id, {
		"turn_number": turn_number,
		"actions_taken": actions_taken
	}, game_state)

func track_performance_sample(fps: float, frame_time: float, memory_mb: float) -> void:
	var AnalyticsEventType = EventType  # Local reference
	track_event(AnalyticsEventType.PERFORMANCE_SAMPLE, -1, {
		"fps": fps,
		"frame_time": frame_time,
		"memory_mb": memory_mb
	})
	
	# Update performance metrics
	performance_metrics.avg_fps = (performance_metrics.avg_fps + fps) / 2.0
	performance_metrics.min_fps = min(performance_metrics.min_fps, fps)
	performance_metrics.max_fps = max(performance_metrics.max_fps, fps)
	performance_metrics.avg_frame_time = (performance_metrics.avg_frame_time + frame_time) / 2.0
	performance_metrics.memory_usage = memory_mb
	
	if fps < 30:
		performance_metrics.frame_drops += 1

# Analytics queries and reports
func get_session_summary(session_id: String = "") -> Dictionary:
	var session = current_session
	if session_id != "":
		for s in all_sessions:
			if s.session_id == session_id:
				session = s
				break
	
	if not session:
		return {}
	
	var summary = {
		"session_id": session.session_id,
		"duration": session.duration,
		"player_count": session.player_count,
		"total_turns": session.total_turns,
		"winner_id": session.winner_id,
		"events_count": session.events.size(),
		"events_by_type": {}
	}
	
	# Count events by type
	for event_type in EventType.values():
		summary.events_by_type[EventType.keys()[event_type]] = 0
	
	for event in session.events:
		summary.events_by_type[EventType.keys()[event.event_type]] += 1
	
	return summary

func get_player_analytics(player_id: int) -> Dictionary:
	var analytics = {
		"player_id": player_id,
		"total_games": 0,
		"wins": 0,
		"total_turns": 0,
		"total_actions": 0,
		"avg_actions_per_turn": 0.0,
		"favorite_strategies": [],
		"performance_trends": {}
	}
	
	var total_actions = 0
	var total_turns = 0
	
	for session in all_sessions:
		var player_participated = false
		var player_actions = 0
		var player_turns = 0
		
		for event in session.events:
			if event.player_id == player_id:
				player_participated = true
				if event.event_type == EventType.PLAYER_ACTION:
					player_actions += 1
				elif event.event_type == EventType.TURN_END:
					player_turns += 1
		
		if player_participated:
			analytics.total_games += 1
			total_actions += player_actions
			total_turns += player_turns
			
			if session.winner_id == player_id:
				analytics.wins += 1
	
	analytics.total_actions = total_actions
	analytics.total_turns = total_turns
	if total_turns > 0:
		analytics.avg_actions_per_turn = float(total_actions) / float(total_turns)
	
	return analytics

func get_game_balance_report() -> Dictionary:
	var report = {
		"total_games": all_sessions.size(),
		"average_game_duration": 0.0,
		"win_distribution": {},
		"unit_usage_stats": {},
		"terrain_impact": {},
		"balance_issues": []
	}
	
	if all_sessions.is_empty():
		return report
	
	# Calculate average game duration
	var total_duration = 0.0
	for session in all_sessions:
		total_duration += session.duration
	report.average_game_duration = total_duration / all_sessions.size()
	
	# Win distribution
	var wins_by_player = {}
	for session in all_sessions:
		if session.winner_id != -1:
			if session.winner_id not in wins_by_player:
				wins_by_player[session.winner_id] = 0
			wins_by_player[session.winner_id] += 1
	
	report.win_distribution = wins_by_player
	
	# Detect balance issues
	if wins_by_player.size() > 1:
		var win_counts = wins_by_player.values()
		var max_wins = win_counts.max()
		var min_wins = win_counts.min()
		
		if max_wins > min_wins * 2:
			report.balance_issues.append("Significant win rate imbalance detected")
	
	return report

func get_performance_report() -> Dictionary:
	return {
		"current_metrics": performance_metrics,
		"recommendations": _generate_performance_recommendations(),
		"trends": _analyze_performance_trends()
	}

# Export analytics data
func export_analytics_data() -> String:
	var export_data = {
		"timestamp": Time.get_time_dict_from_system(),
		"sessions": [],
		"performance_metrics": performance_metrics,
		"balance_metrics": balance_metrics,
		"player_metrics": player_metrics
	}
	
	for session in all_sessions:
		var session_data = {
			"session_id": session.session_id,
			"start_time": session.start_time,
			"end_time": session.end_time,
			"duration": session.duration,
			"player_count": session.player_count,
			"winner_id": session.winner_id,
			"total_turns": session.total_turns,
			"events": []
		}
		
		for event in session.events:
			session_data.events.append(event.to_dict())
		
		export_data.sessions.append(session_data)
	
	return JSON.stringify(export_data, "\t")

func export_csv_report() -> String:
	var csv_lines = ["Session ID,Duration,Player Count,Winner,Total Turns,Events Count"]
	
	for session in all_sessions:
		var line = "%s,%.1f,%d,%d,%d,%d" % [
			session.session_id,
			session.duration,
			session.player_count,
			session.winner_id,
			session.total_turns,
			session.events.size()
		]
		csv_lines.append(line)
	
	return "\n".join(csv_lines)

# Helper methods
func _create_state_snapshot(game_state: Dictionary) -> Dictionary:
	if game_state.is_empty():
		return {}
	
	# Create lightweight snapshot
	return {
		"turn_number": game_state.get("turn_data", {}).get("turn_number", 0),
		"current_player": game_state.get("turn_data", {}).get("current_player_id", -1),
		"unit_count": game_state.get("units", {}).size(),
		"player_count": game_state.get("players", {}).size()
	}

func _update_metrics(event: AnalyticsEvent) -> void:
	# Update various metrics based on event type
	match event.event_type:
		EventType.UNIT_MOVE:
			if event.player_id not in player_metrics.actions_per_turn:
				player_metrics.actions_per_turn[event.player_id] = []
			# Track action frequency
		EventType.PERFORMANCE_SAMPLE:
			# Performance metrics updated in track_performance_sample
			pass

func _generate_performance_recommendations() -> Array:
	var recommendations = []
	
	if performance_metrics.avg_fps < 45:
		recommendations.append("Consider optimizing rendering or reducing visual effects")
	
	if performance_metrics.memory_usage > 200:
		recommendations.append("Memory usage is high, consider object pooling")
	
	if performance_metrics.frame_drops > 10:
		recommendations.append("Frequent frame drops detected, investigate performance bottlenecks")
	
	return recommendations

func _analyze_performance_trends() -> Dictionary:
	return {
		"fps_stable": performance_metrics.max_fps - performance_metrics.min_fps < 20,
		"memory_growth": performance_metrics.memory_usage > 100,
		"frame_consistency": performance_metrics.frame_drops < 5
	}