# 👁️ TOGGLE FOG USE CASE
# Purpose: Orchestrate fog of war toggle
# Layer: Application/UseCases
# Dependencies: Services only

class_name ToggleFogUseCase
extends RefCounted

static func execute(game_state: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"fog_enabled": true
	}
	
	# Toggle fog state
	game_state.fog_of_war_enabled = not game_state.fog_of_war_enabled
	
	result.success = true
	result.fog_enabled = game_state.fog_of_war_enabled
	result.message = "Fog of war %s" % ("enabled" if result.fog_enabled else "disabled")
	
	return result