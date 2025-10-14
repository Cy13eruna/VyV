# 🎯 EMOJI VISIBILITY RULES
# Purpose: Define universal rules for emoji visibility in the game
# Layer: Presentation Constants

extends RefCounted
class_name EmojiVisibilityRules

# UNIVERSAL EMOJI RULE:
# All unit emojis (🗡 fighter, ♥ healer, 🩹 injured, etc.) are ALWAYS visible 
# to all players regardless of unit ownership or team affiliation.
#
# RATIONALE:
# - Provides strategic information to all players
# - Allows tactical planning based on enemy unit types
# - Maintains game balance by giving equal information access
# - Enhances gameplay depth through visible unit specializations
#
# VISIBILITY BOUNDARIES:
# - Emojis respect fog of war (if enabled)
# - Emojis are only hidden if the position itself is not visible
# - Unit ownership does NOT affect emoji visibility
# - Team affiliation does NOT affect emoji visibility
#
# AFFECTED EMOJIS:
# - 🗡 Fighter indicators
# - ♥ Healer indicators  
# - 🩹 Health/injury indicators
# - Any future unit type indicators
#
# IMPLEMENTATION:
# All emoji rendering functions should use _should_show_emoji() 
# from RenderingManager to apply this rule consistently.

# Documentation constants
const RULE_NAME = "Universal Emoji Visibility"
const RULE_VERSION = "1.0"
const RULE_DESCRIPTION = "All unit emojis are visible to all players, respecting only position visibility"

# Emoji types covered by this rule
const COVERED_EMOJIS = [
	"🗡",  # Fighter
	"♥",   # Healer
	"🩹",  # Injured/Health
	# Add new emoji types here as they are implemented
]