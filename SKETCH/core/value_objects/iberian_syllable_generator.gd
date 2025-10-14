# 🏛️ IBERIAN SYLLABLE GENERATOR (FINAL NATURAL)
# Purpose: Generate names using fragments from real Portuguese/Brazilian names
# Layer: Core/Value Objects
# Features: 100% natural-sounding names based on real name patterns

extends RefCounted
class_name IberianSyllableGenerator

# REAL NAME FRAGMENTS - extracted from actual Portuguese/Brazilian names
static var INITIAL_SYLLABLES = {
	"A": ["Ana", "Al", "An", "Ar", "Aldo", "André", "Antô"],
	"B": ["Beto", "Bela", "Bru", "Ber", "Bár", "Bea", "Ben", "Bia"],
	"C": ["Car", "Cel", "Cé", "Clau", "Cris", "Cla", "César", "Cai"],
	"D": ["Davi", "Dara", "Dani", "Dia", "Dé", "Dou", "Dal", "Den"],
	"E": ["Eva", "Eli", "Edu", "Éri", "Emí", "Ester", "Edi", "Ema"],
	"F": ["Fá", "Fer", "Feli", "Fran", "Fla", "Flo", "Fabi", "Feli"],
	"G": ["Gil", "Gabi", "Gus", "Gui", "Gra", "Ger", "Gla", "Gilda"],
	"H": ["Hugo", "Hel", "Hen", "Hei", "Hor", "Hil", "Hana", "Hele"],
	"I": ["Isa", "Ivo", "Ira", "Ilda", "Iris", "Ivan", "Ines", "Ida"],
	"J": ["João", "José", "Ju", "Jor", "Jani", "Jessi", "Joa", "Jer"],
	"K": ["Kar", "Kel", "Kei", "Kla", "Kris", "Karina", "Kat", "Ken"],
	"L": ["Lu", "Lar", "Lei", "Lia", "Lor", "Luc", "Lara", "Leo"],
	"M": ["Ma", "Mar", "Mel", "Mi", "Mô", "Manu", "Mila", "Má"],
	"N": ["Ni", "Nel", "Nor", "Nuno", "Nina", "Ná", "Nara", "Nei"],
	"O": ["Oli", "Os", "Oto", "Oma", "Ora", "Olí", "Osmar", "Odi"],
	"P": ["Pau", "Pe", "Pri", "Pa", "Pé", "Poli", "Pra", "Pila"],
	"Q": ["Qui", "Quin", "Quel", "Quei", "Qua", "Quim", "Quer", "Quil"],
	"R": ["Ri", "Ro", "Rafa", "Rena", "Rui", "Rita", "Rober", "Regi"],
	"S": ["Sil", "Sara", "Sér", "So", "Sô", "Sabi", "Sal", "San"],
	"T": ["Teo", "Ta", "Ter", "Ti", "Tâ", "Tali", "Tomás", "Tai"],
	"U": ["Ul", "Ur", "Uma", "Ula", "Udi", "Ugo", "Una", "Uri"],
	"V": ["Vi", "Val", "Ver", "Vâ", "Vitor", "Vera", "Vivi", "Van"],
	"W": ["Wal", "Wel", "Wil", "War", "Wei", "Win", "Wan", "Wes"],
	"X": ["Xa", "Xavi", "Xan", "Xel", "Xil", "Xara", "Xen", "Xina"],
	"Y": ["Ya", "Yara", "Yas", "Yor", "Yuri", "Yana", "Yel", "Yin"],
	"Z": ["Zé", "Zara", "Zil", "Zu", "Zeca", "Zina", "Zel", "Zora"]
}

# REAL ENDINGS - from actual Portuguese/Brazilian names
static var FINAL_SYLLABLES = [
	# Single letters (very common in Portuguese names)
	"a", "e", "i", "o",
	# Common Portuguese endings
	"ar", "er", "ir", "or",
	"an", "en", "in", "on",
	"al", "el", "il", "ol",
	"as", "es", "is", "os",
	# Real name endings
	"la", "lo", "ra", "ro", "na", "no",
	"ta", "to", "da", "do", "sa", "so",
	"ca", "co", "ga", "go", "ba", "bo",
	"ma", "mo", "pa", "po", "va", "vo",
	# Portuguese specific
	"ão", "ões", "ãe", "inha", "inho"
]

# DOMAIN ENDINGS - based on real place names in Portugal/Brazil
static var DOMAIN_ENDINGS = [
	# Real Portuguese place endings
	"ia", "eira", "inha", "ania", "ória",
	"anda", "enda", "inda", "onda",
	"arga", "erga", "orga",
	"ália", "élia", "ília",
	"ânia", "ênia", "ônia",
	# Brazilian place endings
	"ara", "era", "ira", "ora", "ura",
	"ala", "ela", "ila", "ola", "ula",
	"ama", "ema", "ima", "oma", "uma",
	# Short and natural
	"a", "e", "i", "o", "u"
]

# SIMPLIFIED compatibility - based on real Portuguese phonetics
static var VOWEL_HARMONY = {
	"a": ["a", "e", "i", "o"],      # Very flexible
	"e": ["e", "a", "i"],           # Front vowels
	"i": ["i", "a", "e"],           # High front
	"o": ["o", "a", "u"],           # Back vowels
	"u": ["u", "o", "a"]            # High back
}

# Generate unit name for specific domain initial
static func generate_unit_name_for_domain(domain, game_state: Dictionary) -> String:
	var domain_initial = domain.get("initial", "")
	if domain_initial == "":
		return "Unknown"
	
	# Get existing names for uniqueness check
	var existing_names = _get_all_existing_unit_names(game_state)
	
	# Try to generate unique name with domain initial
	for attempt in range(30):  # Reduced attempts for speed
		var name = _generate_real_name_pattern(domain_initial, false, existing_names)
		if name.length() <= 5 and name not in existing_names:
			return name
	
	# Fallback to numbered variant
	return _generate_fallback_name(domain_initial, existing_names)

# Generate domain name with given initial
static func generate_domain_name(initial: String, game_state: Dictionary) -> String:
	# Get existing domain names for uniqueness check
	var existing_names = _get_all_existing_domain_names(game_state)
	
	# Try to generate unique domain name
	for attempt in range(30):
		var name = _generate_real_name_pattern(initial, true, existing_names)
		if name not in existing_names:
			return name
	
	# Fallback to numbered variant
	return _generate_fallback_domain_name(initial, existing_names)

# Generate random unit name (any initial)
static func generate_random_unit_name(game_state: Dictionary) -> String:
	var existing_names = _get_all_existing_unit_names(game_state)
	var all_initials = INITIAL_SYLLABLES.keys()
	
	# Try random initials until we find a unique name
	for attempt in range(30):
		var random_initial = all_initials[randi() % all_initials.size()]
		var name = _generate_real_name_pattern(random_initial, false, existing_names)
		if name.length() <= 5 and name not in existing_names:
			return name
	
	# Ultimate fallback
	return _generate_fallback_name("U", existing_names)

# CORE: Generate names using real Portuguese name patterns
static func _generate_real_name_pattern(initial: String, is_domain: bool, existing_names: Array) -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Get real name fragments for the letter
	var initial_fragments = INITIAL_SYLLABLES.get(initial, ["Un"])
	var chosen_initial = initial_fragments[rng.randi() % initial_fragments.size()]
	
	# STRATEGY: 90% of names are just the initial fragment + simple ending
	var use_simple_pattern = rng.randf() < 0.9
	
	if use_simple_pattern:
		# Simple pattern: Real fragment + natural ending
		var final_syllables = DOMAIN_ENDINGS if is_domain else FINAL_SYLLABLES
		var final_syllable = _get_natural_ending(chosen_initial, final_syllables, rng)
		
		var full_name = chosen_initial + final_syllable
		return _capitalize_like_real_name(full_name)
	else:
		# Occasionally use a more complex pattern (but still natural)
		var middle_vowel = _get_simple_vowel(chosen_initial, rng)
		var final_syllables = DOMAIN_ENDINGS if is_domain else FINAL_SYLLABLES
		var final_syllable = _get_natural_ending(middle_vowel, final_syllables, rng)
		
		var full_name = chosen_initial + middle_vowel + final_syllable
		return _capitalize_like_real_name(full_name)

# Get natural ending that sounds like real Portuguese names
static func _get_natural_ending(base_fragment: String, final_pool: Array, rng: RandomNumberGenerator) -> String:
	var last_vowel = _get_last_vowel_real(base_fragment)
	var compatible_endings = []
	
	# Filter endings that sound natural with this base
	for ending in final_pool:
		if _sounds_natural_together(base_fragment, ending):
			compatible_endings.append(ending)
	
	if compatible_endings.size() > 0:
		return compatible_endings[rng.randi() % compatible_endings.size()]
	
	# Fallback to most common Portuguese endings
	var common_endings = ["a", "o", "e", "ar", "er", "ir"]
	return common_endings[rng.randi() % common_endings.size()]

# Check if base + ending sounds like a real Portuguese name
static func _sounds_natural_together(base: String, ending: String) -> bool:
	var full_name = base + ending
	var full_lower = full_name.to_lower()
	
	# Avoid awkward repetitions
	if base.to_lower().ends_with(ending.to_lower()):
		return false
	
	# Avoid double vowels that don't exist in Portuguese
	var awkward_vowel_pairs = ["aa", "ee", "ii", "oo", "uu", "ae", "oe", "ie"]
	for pair in awkward_vowel_pairs:
		if pair in full_lower:
			return false
	
	# Avoid awkward consonant clusters
	var awkward_consonants = ["rr", "ll", "ss", "nn", "mm", "pp", "tt", "dd"]
	for cluster in awkward_consonants:
		if cluster in full_lower:
			return false
	
	# Prefer shorter combinations for units
	if full_name.length() > 5:
		return false
	
	return true

# Get simple vowel for middle syllable
static func _get_simple_vowel(base_fragment: String, rng: RandomNumberGenerator) -> String:
	var last_vowel = _get_last_vowel_real(base_fragment)
	var harmony_vowels = VOWEL_HARMONY.get(last_vowel, ["a", "e", "i", "o"])
	
	return harmony_vowels[rng.randi() % harmony_vowels.size()]

# Extract last vowel (simplified for real names)
static func _get_last_vowel_real(fragment: String) -> String:
	var vowels = ["a", "e", "i", "o", "u"]
	for i in range(fragment.length() - 1, -1, -1):
		var char = fragment[i].to_lower()
		if char in vowels:
			return char
	return "a"

# Capitalize like real Portuguese names
static func _capitalize_like_real_name(name: String) -> String:
	if name.length() == 0:
		return name
	
	# Simple capitalization - first letter uppercase, rest lowercase
	var result = name[0].to_upper() + name.substr(1).to_lower()
	
	# Handle special Portuguese cases
	result = result.replace("joão", "João")
	result = result.replace("josé", "José")
	result = result.replace("são", "São")
	
	return result

# Get all existing unit names
static func _get_all_existing_unit_names(game_state: Dictionary) -> Array:
	var existing_names = []
	if "units" in game_state:
		for unit_id in game_state.units:
			var unit = game_state.units[unit_id]
			existing_names.append(unit.name)
	return existing_names

# Get all existing domain names
static func _get_all_existing_domain_names(game_state: Dictionary) -> Array:
	var existing_names = []
	if "domains" in game_state:
		for domain_id in game_state.domains:
			var domain = game_state.domains[domain_id]
			existing_names.append(domain.name)
	return existing_names

# Generate fallback name for units
static func _generate_fallback_name(initial: String, existing_names: Array) -> String:
	for i in range(1, 1000):
		var variant = "%s%d" % [initial, i]
		if variant.length() <= 5 and variant not in existing_names:
			return variant
	return "%s%d" % [initial, randi() % 9999]

# Generate fallback name for domains (using natural patterns)
static func _generate_fallback_domain_name(initial: String, existing_names: Array) -> String:
	# Try natural fallback patterns first
	var natural_fallbacks = [
		initial + "aria",
		initial + "eira",
		initial + "anda",
		initial + "ália",
		initial + "ânia"
	]
	
	for fallback in natural_fallbacks:
		if fallback not in existing_names:
			return _capitalize_like_real_name(fallback)
	
	# If natural fallbacks fail, use numbered variants with natural base
	var base_name = initial + "ia"
	for i in range(1, 100):
		var variant = "%s%d" % [base_name, i]
		if variant not in existing_names:
			return _capitalize_like_real_name(variant)
	
	# Ultimate fallback
	return _capitalize_like_real_name(initial + "ia" + str(randi() % 999))

# Get next available initial for new domain
static func get_next_available_initial(game_state: Dictionary) -> String:
	# Get all used initials
	var used_initials = []
	if "domains" in game_state:
		for domain_id in game_state.domains:
			var domain = game_state.domains[domain_id]
			var initial = domain.get("initial", "")
			if initial != "" and initial not in used_initials:
				used_initials.append(initial)
	
	# Create list of all available initials
	var available_initials = []
	for initial in INITIAL_SYLLABLES.keys():
		if initial not in used_initials:
			available_initials.append(initial)
	
	# Return random initial from available ones
	if available_initials.size() > 0:
		var random_index = randi() % available_initials.size()
		return available_initials[random_index]
	
	# Fallback if all letters are used (very unlikely)
	return "Z"

# Calculate total possible combinations (for debugging/info)
static func get_total_possible_combinations() -> int:
	var initial_count = 0
	for initial in INITIAL_SYLLABLES.keys():
		initial_count += INITIAL_SYLLABLES[initial].size()
	
	var final_count = FINAL_SYLLABLES.size()
	var domain_final_count = DOMAIN_ENDINGS.size()
	
	# Mostly simple combinations now
	var unit_combinations = initial_count * final_count
	var domain_combinations = initial_count * domain_final_count
	
	return unit_combinations + domain_combinations

# Debug function to show sample names (real patterns)
static func generate_sample_names(initial: String, count: int = 10) -> Array:
	var samples = []
	var fake_game_state = {"units": {}, "domains": {}}
	
	for i in range(count):
		var unit_name = _generate_real_name_pattern(initial, false, [])
		var domain_name = _generate_real_name_pattern(initial, true, [])
		samples.append({"unit": unit_name, "domain": domain_name})
	
	return samples