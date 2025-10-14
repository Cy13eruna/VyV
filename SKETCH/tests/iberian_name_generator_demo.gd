# 🧪 IBERIAN NAME GENERATOR DEMO
# Purpose: Demonstrate the new Iberian syllable-based name generation system
# Usage: Run this script to see sample names and system capabilities

extends RefCounted

const IberianSyllableGenerator = preload("res://core/value_objects/iberian_syllable_generator.gd")

# Demo function to show the new system capabilities
static func run_demo():
	print("🏛️ IBERIAN SYLLABLE NAME GENERATOR DEMO")
	print("=" * 50)
	
	# Show total possible combinations
	var total_combinations = IberianSyllableGenerator.get_total_possible_combinations()
	print("📊 ESTIMATED TOTAL COMBINATIONS: ", total_combinations)
	print()
	
	# Demo for each letter
	var demo_letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
	
	for letter in demo_letters:
		print("🔤 LETTER '%s' SAMPLES:" % letter)
		var samples = IberianSyllableGenerator.generate_sample_names(letter, 5)
		
		for i in range(samples.size()):
			var sample = samples[i]
			print("   Unit: %-8s | Domain: %s" % [sample.unit, sample.domain])
		print()
	
	# Demo uniqueness with fake game state
	print("🎯 UNIQUENESS TEST:")
	var fake_game_state = {
		"units": {},
		"domains": {}
	}
	
	# Generate 20 unit names and check for duplicates
	var generated_unit_names = []
	for i in range(20):
		var name = IberianSyllableGenerator.generate_random_unit_name(fake_game_state)
		generated_unit_names.append(name)
		# Add to fake game state to test uniqueness
		fake_game_state.units[i] = {"name": name}
	
	print("Generated 20 unit names:")
	for name in generated_unit_names:
		print("   - %s" % name)
	
	# Check for duplicates
	var unique_names = []
	for name in generated_unit_names:
		if name not in unique_names:
			unique_names.append(name)
	
	print("✅ Uniqueness: %d/%d names are unique" % [unique_names.size(), generated_unit_names.size()])
	print()
	
	# Demo domain names
	print("🏰 DOMAIN NAME SAMPLES:")
	var domain_samples = []
	for i in range(10):
		var initial = char(65 + i)  # A, B, C, etc.
		var domain_name = IberianSyllableGenerator.generate_domain_name(initial, fake_game_state)
		domain_samples.append("%s: %s" % [initial, domain_name])
	
	for sample in domain_samples:
		print("   %s" % sample)
	print()
	
	print("🎉 DEMO COMPLETE!")
	print("The new system can generate thousands of unique, phonetically pleasing names")
	print("using authentic Iberian syllable combinations with proper vowel harmony.")

# Function to test specific scenarios
static func test_edge_cases():
	print("🧪 EDGE CASE TESTING:")
	print("=" * 30)
	
	# Test with many existing names
	var crowded_game_state = {
		"units": {},
		"domains": {}
	}
	
	# Fill with 100 existing names
	for i in range(100):
		crowded_game_state.units[i] = {"name": "TestUnit%d" % i}
	
	# Try to generate new unique names
	print("Testing with 100 existing names...")
	for i in range(5):
		var new_name = IberianSyllableGenerator.generate_random_unit_name(crowded_game_state)
		print("   Generated: %s" % new_name)
		crowded_game_state.units[100 + i] = {"name": new_name}
	
	print("✅ Edge case testing complete!")

# Run the demo if this script is executed directly
func _ready():
	run_demo()
	test_edge_cases()