class_name CrystalBlock
extends Node

enum CrystalType {
	ENERGY,    # Blue - Basic energy source
	FIRE,      # Red - Fire element
	WATER,     # Cyan - Water element  
	EARTH,     # Brown - Earth element
	AIR,       # White - Air element
	VOID,      # Purple - Dark/void element
	SOLAR,     # Yellow - Solar power
	LUNAR      # Silver - Lunar power
}

# Crystal properties
static func get_crystal_properties(type: CrystalType) -> Dictionary:
	match type:
		CrystalType.ENERGY:
			return {
				"name": "Energy Crystal",
				"color": Color(0.2, 0.6, 1.0, 0.8),  # Blue with transparency
				"glow_strength": 2.0,
				"energy_output": 10,
				"rarity": 0.15,  # 15% chance in caves
				"min_depth": 20,
				"emission_color": Color(0.4, 0.8, 1.0)
			}
		CrystalType.FIRE:
			return {
				"name": "Fire Crystal", 
				"color": Color(1.0, 0.3, 0.1, 0.8),  # Red-orange
				"glow_strength": 3.0,
				"energy_output": 15,
				"rarity": 0.08,
				"min_depth": 30,
				"emission_color": Color(1.0, 0.5, 0.2)
			}
		CrystalType.WATER:
			return {
				"name": "Water Crystal",
				"color": Color(0.1, 0.8, 1.0, 0.8),  # Cyan
				"glow_strength": 1.5,
				"energy_output": 12,
				"rarity": 0.10,
				"min_depth": 25,
				"emission_color": Color(0.2, 0.9, 1.0)
			}
		CrystalType.EARTH:
			return {
				"name": "Earth Crystal",
				"color": Color(0.6, 0.4, 0.2, 0.8),  # Brown
				"glow_strength": 1.0,
				"energy_output": 20,
				"rarity": 0.12,
				"min_depth": 15,
				"emission_color": Color(0.7, 0.5, 0.3)
			}
		CrystalType.AIR:
			return {
				"name": "Air Crystal",
				"color": Color(0.9, 0.95, 1.0, 0.6),  # Light blue-white
				"glow_strength": 2.5,
				"energy_output": 8,
				"rarity": 0.10,
				"min_depth": 10,
				"emission_color": Color(0.95, 1.0, 1.0)
			}
		CrystalType.VOID:
			return {
				"name": "Void Crystal",
				"color": Color(0.3, 0.1, 0.5, 0.9),  # Dark purple
				"glow_strength": 4.0,
				"energy_output": 25,
				"rarity": 0.03,  # Very rare
				"min_depth": 45,
				"emission_color": Color(0.5, 0.2, 0.8)
			}
		CrystalType.SOLAR:
			return {
				"name": "Solar Crystal",
				"color": Color(1.0, 0.9, 0.3, 0.7),  # Golden yellow
				"glow_strength": 5.0,
				"energy_output": 30,
				"rarity": 0.02,  # Ultra rare, surface only
				"min_depth": -10,  # Negative means above ground
				"emission_color": Color(1.0, 0.95, 0.5)
			}
		CrystalType.LUNAR:
			return {
				"name": "Lunar Crystal",
				"color": Color(0.8, 0.8, 0.9, 0.7),  # Silver
				"glow_strength": 3.5,
				"energy_output": 22,
				"rarity": 0.04,
				"min_depth": 35,
				"emission_color": Color(0.9, 0.9, 1.0)
			}
		_:
			return {}

# Check if crystals can combine for reactions
static func can_combine(crystal1: CrystalType, crystal2: CrystalType) -> bool:
	var combinations = {
		[CrystalType.FIRE, CrystalType.WATER]: true,  # Creates steam power
		[CrystalType.EARTH, CrystalType.AIR]: true,   # Creates dust storm
		[CrystalType.SOLAR, CrystalType.LUNAR]: true, # Creates eclipse power
		[CrystalType.ENERGY, CrystalType.VOID]: true, # Creates antimatter
	}
	
	var key1 = [crystal1, crystal2]
	var key2 = [crystal2, crystal1]
	
	return combinations.has(key1) or combinations.has(key2)

# Get combination result
static func get_combination_result(crystal1: CrystalType, crystal2: CrystalType) -> Dictionary:
	if crystal1 > crystal2:
		var temp = crystal1
		crystal1 = crystal2
		crystal2 = temp
	
	match [crystal1, crystal2]:
		[CrystalType.FIRE, CrystalType.WATER]:
			return {"name": "Steam Power", "energy": 50, "effect": "area_heal"}
		[CrystalType.EARTH, CrystalType.AIR]:
			return {"name": "Sandstorm", "energy": 40, "effect": "area_damage"}
		[CrystalType.SOLAR, CrystalType.LUNAR]:
			return {"name": "Eclipse Energy", "energy": 100, "effect": "time_control"}
		[CrystalType.ENERGY, CrystalType.VOID]:
			return {"name": "Antimatter", "energy": 150, "effect": "teleportation"}
		_:
			return {}