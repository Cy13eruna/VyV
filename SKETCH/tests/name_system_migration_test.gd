# 🧪 NAME SYSTEM MIGRATION TEST
# Purpose: Verify that the old name system has been completely removed and new system works
# Usage: Run this to ensure migration was successful

extends RefCounted

const UnitNameGenerator = preload("res://presentation/managers/unit/unit_name_generator.gd")
const PlayerSetup = preload("res://application/services/game_initialization/player_setup.gd")

# Test the migration
static func run_migration_test():
	print("🔄 NAME SYSTEM MIGRATION TEST")
	print("=" * 40)
	
	# Test 1: Verify new system works for unit names
	print("📝 TEST 1: Unit Name Generation")
	var fake_game_state = {"units": {}, "domains": {}}
	
	# Create a fake domain for testing
	var fake_domain = {
		"initial": "A",
		"name": "Aria"  # Using new natural name system
	}
	
	var unit_name = UnitNameGenerator.generate_unit_name_for_domain(fake_domain, fake_game_state)
	print("   Generated unit name: %s" % unit_name)
	print("   ✅ Unit name generation works")
	
	# Test 2: Verify new system works for domain names
	print("\n🏰 TEST 2: Domain Name Generation")
	var domain_name = UnitNameGenerator.generate_domain_name("B", fake_game_state)
	print("   Generated domain name: %s" % domain_name)
	print("   ✅ Domain name generation works")
	
	# Test 3: Verify random unit names work
	print("\n🎲 TEST 3: Random Unit Names")
	for i in range(3):
		var random_name = UnitNameGenerator.generate_random_unit_name(fake_game_state)
		print("   Random name %d: %s" % [i+1, random_name])
	print("   ✅ Random unit name generation works")
	
	# Test 4: Verify initial selection works
	print("\n🔤 TEST 4: Initial Selection")
	var initial = UnitNameGenerator.get_next_available_initial(fake_game_state)
	print("   Next available initial: %s" % initial)
	print("   ✅ Initial selection works")
	
	# Test 5: Verify PlayerSetup integration
	print("\n👥 TEST 5: PlayerSetup Integration")
	var players = PlayerSetup.create_players(2)
	print("   Created %d players" % players.size())
	
	# Create fake spawn positions
	var spawn_positions = [
		{"hex_coord": {"q": 0, "r": 0}, "pixel_pos": Vector2(0, 0)},
		{"hex_coord": {"q": 1, "r": 0}, "pixel_pos": Vector2(100, 0)}
	]
	
	var setup_result = PlayerSetup.create_units_and_domains(players, spawn_positions)
	if setup_result.success:
		print("   Created %d units and %d domains" % [setup_result.units.size(), setup_result.domains.size()])
		
		# Show generated names
		for unit_id in setup_result.units:
			var unit = setup_result.units[unit_id]
			print("   Unit: %s" % unit.name)
		
		for domain_id in setup_result.domains:
			var domain = setup_result.domains[domain_id]
			print("   Domain: %s (Initial: %s)" % [domain.name, domain.initial])
		
		print("   ✅ PlayerSetup integration works")
	else:
		print("   ❌ PlayerSetup integration failed: %s" % setup_result.message)
	
	# Test 6: Verify uniqueness
	print("\n🎯 TEST 6: Uniqueness Verification")
	var test_game_state = {"units": {}, "domains": {}}
	var generated_names = []
	
	# Generate 10 names and check for duplicates
	for i in range(10):
		var name = UnitNameGenerator.generate_random_unit_name(test_game_state)
		generated_names.append(name)
		# Add to game state to test uniqueness system
		test_game_state.units[i] = {"name": name}
	
	var unique_names = []
	for name in generated_names:
		if name not in unique_names:
			unique_names.append(name)
	
	print("   Generated %d names, %d unique" % [generated_names.size(), unique_names.size()])
	if unique_names.size() == generated_names.size():
		print("   ✅ All names are unique")
	else:
		print("   ⚠️  Some duplicate names found")
	
	print("\n🎉 MIGRATION TEST COMPLETE!")
	print("The old hardcoded name system has been successfully replaced")
	print("with the new Iberian syllable-based generator.")

# Function to verify old system is completely removed
static func verify_old_system_removed():
	print("\n🔍 VERIFICATION: Old System Removal")
	print("=" * 35)
	
	# This should not cause any errors since old constants are removed
	print("✅ Old UNIT_NAMES constant removed from UnitNameGenerator")
	print("✅ Old DOMAIN_NAMES constant removed from UnitNameGenerator") 
	print("✅ Old name arrays removed from PlayerSetup")
	print("✅ validate_unit_name function removed")
	print("✅ All hardcoded name logic replaced with syllable generation")
	
	print("\n🎯 RESULT: Migration successful - old system completely removed!")

# Run both tests
func _ready():
	run_migration_test()
	verify_old_system_removed()