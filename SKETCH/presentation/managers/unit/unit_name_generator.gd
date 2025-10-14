# 📝 UNIT NAME GENERATOR
# Purpose: Generate unique names for units and domains using Iberian syllables
# Layer: Presentation Manager Utility
# Features: Thousands of combinations using syllable-based generation

extends RefCounted
class_name UnitNameGenerator

# Import the Iberian syllable generator
const IberianSyllableGenerator = preload("res://core/value_objects/iberian_syllable_generator.gd")

# SYSTEM CAPABILITIES:
# - 50,000+ unique unit name combinations using authentic Iberian syllables
# - 100,000+ unique domain name combinations with grandiose endings
# - Phonetic harmony rules for natural-sounding names
# - Respects domain initial requirements and ensures global uniqueness
# - Robust fallback systems prevent naming conflicts
# - Supports Spanish, Portuguese, Catalan, Galician, and Basque influences

# Generate unit name for specific domain (uses domain's initial)
static func generate_unit_name_for_domain(domain, game_state: Dictionary) -> String:
	return IberianSyllableGenerator.generate_unit_name_for_domain(domain, game_state)

# Generate names for new units (completely independent)
static func generate_unit_name(player_id: int, unit_type: String, game_state: Dictionary) -> String:
	return generate_random_unit_name(game_state)

# Generate random unit name from any initial (no domain dependency)
static func generate_random_unit_name(game_state: Dictionary) -> String:
	return IberianSyllableGenerator.generate_random_unit_name(game_state)

# Get random available initial for new domain
static func get_next_available_initial(game_state: Dictionary) -> String:
	return IberianSyllableGenerator.get_next_available_initial(game_state)

# Generate domain name with given initial
static func generate_domain_name(initial: String, game_state: Dictionary) -> String:
	return IberianSyllableGenerator.generate_domain_name(initial, game_state)

# Utility function to get total possible combinations (for debugging)
static func get_total_possible_combinations() -> int:
	return IberianSyllableGenerator.get_total_possible_combinations()

# Generate sample names for testing/demonstration
static func generate_sample_names(initial: String, count: int = 5) -> Array:
	return IberianSyllableGenerator.generate_sample_names(initial, count)