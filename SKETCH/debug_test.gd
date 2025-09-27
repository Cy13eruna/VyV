extends Node

# Simple debug test to check system functionality

func _ready():
	print("🔧 DEBUG TEST: Starting system checks...")
	
	# Test 1: Check if autoloads are available
	print("🔧 DEBUG TEST: Checking autoloads...")
	if GameConstants:
		print("✅ GameConstants available")
	else:
		print("❌ GameConstants NOT available")
	
	if TerrainSystem:
		print("✅ TerrainSystem available")
	else:
		print("❌ TerrainSystem NOT available")
	
	if HexGridSystem:
		print("✅ HexGridSystem available")
	else:
		print("❌ HexGridSystem NOT available")
	
	if GameManager:
		print("✅ GameManager available")
	else:
		print("❌ GameManager NOT available")
	
	if PowerSystem:
		print("✅ PowerSystem available")
		# Test PowerSystem functionality
		PowerSystem.initialize()
		PowerSystem.setup_domains(0, 1, "TestDomain1", "TestDomain2")
		print("🔧 Initial power: P1=%d, P2=%d" % [PowerSystem.get_player_power(1), PowerSystem.get_player_power(2)])
		
		# Test power generation
		PowerSystem.update_game_state({"current_player": 1, "unit1_position": 0, "unit2_position": 1})
		PowerSystem.generate_power_for_current_player()
		print("🔧 After generation: P1=%d, P2=%d" % [PowerSystem.get_player_power(1), PowerSystem.get_player_power(2)])
	else:
		print("❌ PowerSystem NOT available")
	
	print("🔧 DEBUG TEST: System checks complete")
	
	# Quit after test
	get_tree().quit()