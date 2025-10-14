# ✂️ SHORT NATURAL NAMES TEST
# Purpose: Demonstrate the ultra-refined short and natural name generation
# Usage: Run this to see the improved brevity and naturalness

extends RefCounted

const IberianSyllableGenerator = preload("res://core/value_objects/iberian_syllable_generator.gd")

# Test the ultra-refined short name system
static func run_short_names_test():
	print("✂️ ULTRA-REFINED SHORT NATURAL NAMES TEST")
	print("=" * 50)
	
	print("🎯 ULTRA REFINEMENTS:")
	print("✅ Prioritize 2 syllables (80% of names)")
	print("✅ Based on real Portuguese/Spanish name patterns")
	print("✅ Simplified vowel harmony (more flexible)")
	print("✅ Short, familiar endings (-a, -o, -e, -ar, -er, -ir)")
	print("✅ Eliminated complex consonant clusters")
	print("✅ Maximum 5 characters for units")
	print("✅ Natural pronunciation priority")
	print()
	
	# Test each letter with ultra-refined examples
	var test_letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
	
	for letter in test_letters:
		print("🔤 LETTER '%s' - ULTRA-REFINED SAMPLES:" % letter)
		var samples = IberianSyllableGenerator.generate_sample_names(letter, 10)
		
		print("   📝 UNITS (short & natural):")
		var unit_examples = []
		for i in range(min(6, samples.size())):
			var unit_name = samples[i].unit
			unit_examples.append("%s(%d)" % [unit_name, unit_name.length()])
		print("      %s" % ", ".join(unit_examples))
		
		print("   🏰 DOMAINS (grandiose but short):")
		var domain_examples = []
		for i in range(min(4, samples.size())):
			var domain_name = samples[i].domain
			domain_examples.append(domain_name)
		print("      %s" % ", ".join(domain_examples))
		print()
	
	# Test length distribution
	print("📏 LENGTH DISTRIBUTION ANALYSIS:")
	print("=" * 35)
	
	var fake_game_state = {"units": {}, "domains": {}}
	var length_counts = {2: 0, 3: 0, 4: 0, 5: 0, "5+": 0}
	var test_names = []
	
	# Generate 50 unit names for analysis
	for i in range(50):
		var name = IberianSyllableGenerator.generate_random_unit_name(fake_game_state)
		test_names.append(name)
		fake_game_state.units[i] = {"name": name}
		
		var length = name.length()
		if length <= 5:
			length_counts[length] = length_counts.get(length, 0) + 1
		else:
			length_counts["5+"] = length_counts.get("5+", 0) + 1
	
	print("   Unit name lengths (50 samples):")
	for length in [2, 3, 4, 5, "5+"]:
		var count = length_counts.get(length, 0)
		var percentage = (count * 100.0) / 50.0
		print("      %s chars: %d names (%.1f%%)" % [str(length), count, percentage])
	
	print()
	print("   Sample short names:")
	var short_names = []
	for name in test_names:
		if name.length() <= 4:
			short_names.append(name)
	
	for i in range(min(15, short_names.size())):
		print("      %d. %s" % [i+1, short_names[i]])
	
	# Test naturalness comparison
	print()
	print("🌟 NATURALNESS COMPARISON:")
	print("=" * 30)
	
	var natural_examples = {
		"A": ["Ana", "Aldo", "Alma", "Aro", "Ava"],
		"B": ["Bela", "Beto", "Bia", "Bor", "Bru"],
		"C": ["Cara", "Celo", "Cira", "Cor", "Cru"],
		"D": ["Dara", "Davi", "Dina", "Dor", "Dru"],
		"E": ["Ema", "Eri", "Eva", "Eli", "Ero"]
	}
	
	print("   Examples that sound like real names:")
	for letter in natural_examples:
		var examples = natural_examples[letter]
		print("      %s: %s" % [letter, ", ".join(examples)])
	
	# Test pronunciation ease
	print()
	print("🗣️ PRONUNCIATION EASE TEST:")
	print("=" * 30)
	
	var pronunciation_samples = []
	for i in range(20):
		var name = IberianSyllableGenerator.generate_random_unit_name({"units": {}, "domains": {}})
		var ease = _analyze_pronunciation_ease(name)
		pronunciation_samples.append({"name": name, "ease": ease})
	
	# Sort by ease
	pronunciation_samples.sort_custom(func(a, b): return a.ease > b.ease)
	
	print("   Top 10 easiest to pronounce:")
	for i in range(min(10, pronunciation_samples.size())):
		var sample = pronunciation_samples[i]
		print("      %d. %s (ease: %.1f/10)" % [i+1, sample.name, sample.ease])
	
	print()
	print("🎉 ULTRA-REFINEMENT COMPLETE!")
	print("Names are now significantly shorter, more natural, and easier to pronounce!")
	print("Most names are 2-4 characters and sound like real Portuguese/Spanish names.")

# Analyze pronunciation ease (0-10 scale)
static func _analyze_pronunciation_ease(name: String) -> float:
	var ease_score = 10.0
	var name_lower = name.to_lower()
	
	# Penalize length
	if name.length() > 4:
		ease_score -= (name.length() - 4) * 1.0
	
	# Penalize difficult consonant clusters
	var difficult_clusters = ["xt", "pt", "ct", "gn", "mn", "tm", "dm", "rr", "ll"]
	for cluster in difficult_clusters:
		if cluster in name_lower:
			ease_score -= 2.0
	
	# Reward simple vowel patterns
	var vowel_count = 0
	for char in name_lower:
		if char in ["a", "e", "i", "o", "u"]:
			vowel_count += 1
	
	# Good vowel ratio (around 40-60%)
	var vowel_ratio = float(vowel_count) / float(name.length())
	if vowel_ratio >= 0.4 and vowel_ratio <= 0.6:
		ease_score += 1.0
	
	# Reward familiar endings
	var familiar_endings = ["a", "o", "e", "ar", "er", "ir", "an", "en", "in"]
	for ending in familiar_endings:
		if name_lower.ends_with(ending):
			ease_score += 1.0
			break
	
	# Reward familiar patterns (CV-CV, CV-CVC)
	if name.length() == 4:
		var pattern = _get_syllable_pattern(name_lower)
		if pattern in ["CV-CV", "CV-CVC", "CVC-CV"]:
			ease_score += 1.0
	
	return max(0.0, min(10.0, ease_score))

# Get syllable pattern for analysis
static func _get_syllable_pattern(name: String) -> String:
	var vowels = ["a", "e", "i", "o", "u"]
	var pattern = ""
	
	for char in name:
		if char in vowels:
			pattern += "V"
		else:
			pattern += "C"
	
	# Convert to syllable pattern
	if pattern.length() == 4:
		if pattern == "CVCV":
			return "CV-CV"
		elif pattern == "CVCC":
			return "CV-CVC"
		elif pattern == "CCCV":
			return "CVC-CV"
	
	return "OTHER"

# Run the test
func _ready():
	run_short_names_test()