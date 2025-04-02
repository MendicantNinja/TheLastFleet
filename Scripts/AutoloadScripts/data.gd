extends Node
  #.oooooo.    oooooooooooo ooooo      ooo oooooooooooo ooooooooo.         .o.       ooooo             oooooooooooo ooooo      ooo ooooo     ooo ooo        ooooo  .oooooo..o 
 #d8P'  `Y8b   `888'     `8 `888b.     `8' `888'     `8 `888   `Y88.      .888.      `888'             `888'     `8 `888b.     `8' `888'     `8' `88.       .888' d8P'    `Y8 
#888            888          8 `88b.    8   888          888   .d88'     .8"888.      888               888          8 `88b.    8   888       8   888b     d'888  Y88bo.      
#888            888oooo8     8   `88b.  8   888oooo8     888ooo88P'     .8' `888.     888               888oooo8     8   `88b.  8   888       8   8 Y88. .P  888   `"Y8888o.  
#888     ooooo  888    "     8     `88b.8   888    "     888`88b.      .88ooo8888.    888               888    "     8     `88b.8   888       8   8  `888'   888       `"Y88b 
#`88.    .88'   888       o  8       `888   888       o  888  `88b.   .8'     `888.   888       o       888       o  8       `888   `88.    .8'   8    Y     888  oo     .d8P 
 #`Y8bood8P'   o888ooooood8 o8o        `8  o888ooooood8 o888o  o888o o88o     o8888o o888ooooood8      o888ooooood8 o8o        `8     `YbodP'    o8o        o888o 8""88888P'  

enum tech_enum {
	LOW,
	MEDIUM,
	HIGH,
}

																																										   
 #.oooooo..o ooooo   ooooo ooooo ooooooooo.    .oooooo..o 
#d8P'    `Y8 `888'   `888' `888' `888   `Y88. d8P'    `Y8 
#Y88bo.       888     888   888   888   .d88' Y88bo.      
 #`"Y8888o.   888ooooo888   888   888ooo88P'   `"Y8888o.  
	 #`"Y88b  888     888   888   888              `"Y88b 
#oo     .d8P  888     888   888   888         oo     .d8P 
#8""88888P'  o888o   o888o o888o o888o        8""88888P'

# PLEASE READ: Adding entries to the middle of an enum breaks everything else due to numbers being shifted. Godot's fault.
# List of Ships in the game. Matches to a dictionary.
enum ship_type_enum {
	# Fighters (Suggestion: Birds of Prey and Predatory Insects)
	RAPTOR = 0,
	FALCON = 1,
	
	# Frigates (Suggestion: Names of famous battles and reptiles/animals, famous animals?) 
	CHALLENGER = 2,
	ECLIPSE = 3, 
	# Destroyers (Suggestion: Pack animals and Tools. Famous commanders)
	LION = 4,
	WOLF = 5,
	TRIDENT = 6,
	
	# Cruisers (Suggestion: Nouns that are strong actions or suggest grand scale, so that they almost come off as verbs. )
	MARATHON = 7, # Also the name of a famous battle! :D
	INFINITY = 8, 
	
	# Capitals (Suggestion: strong adjectives. Because capital ships do things.)
	ASTRAL = 9,
	MALEVOLENT = 10,
	
	#Motherships
	
	# DEBUG / TEST SHIPS
	TEST = 11,

}

var ship_type_dictionary: Dictionary = {
	#for copy pasting quickly ship_type_enum.RAPTOR : load(),
	# Fighters
	ship_type_enum.RAPTOR : load("res://Resources/ShipHulls/Fighters/Raptor.tres"),
	
	# Frigates
	ship_type_enum.CHALLENGER: load("res://Resources/ShipHulls/Frigates/Challenger.tres"),
	ship_type_enum.ECLIPSE: load("res://Resources/ShipHulls/Frigates/Eclipse.tres"),
	# Destroyers
	ship_type_enum.LION : load("res://Resources/ShipHulls/Destroyers/Lion.tres"),
	
	# Cruisers
	ship_type_enum.MARATHON: load("res://Resources/ShipHulls/Cruisers/Marathon.tres"),
	ship_type_enum.TRIDENT: load("res://Resources/ShipHulls/Cruisers/Trident.tres"),
	
	# Capitals
	ship_type_enum.ASTRAL: load("res://Resources/ShipHulls/Capitals/Astral.tres"),
	
	# Test
	ship_type_enum.TEST: load("res://Resources/ShipHulls/TestHull.tres"),
}

enum loadout_enum {
	DEFAULT,
	ASSAULT,
	LONGRANGE
}
func assign_loadout(ship_stats: ShipStats, loadout_type: loadout_enum = loadout_enum.DEFAULT) -> void:
	var ship_type: ship_type_enum = ship_stats.ship_hull.ship_type
	if loadout_dictionary.has(ship_type) == false: # Return if the ship in question doesn't have a dictionary or loadout entry yet.
		if ship_type != ship_type_enum.TEST:
			print("In data.assign_loadout. Loadout does not exist for this ship, ship will have railguns added by default")
			push_error("In data.assign_loadout. Loadout does not exist for this ship, ship will have railguns added by default")
		return
	var ship_loadouts: Dictionary = loadout_dictionary.get(ship_type)
	if ship_loadouts.has(loadout_type) == false:
		return
	var ship_loadout_array: Array = ship_loadouts.get(loadout_type)
	var weapon_slots: Array[WeaponSlot] = ship_stats.weapon_slots
	var weapon_loadout_array: Array = loadout_dictionary[ship_type].get(loadout_type)
	for i in range(weapon_loadout_array.size()):
		weapon_slots[i].weapon = weapon_loadout_array[i]
	# Useful for assigning ship mods and OP later. Will probably have to add such data to the loadout dictionary
		



	
# Ship size
enum ship_size_enum {
	FIGHTER,
	FRIGATE,
	DESTROYER,
	CRUISER,
	CAPITAL,
	MOTHERSHIP
}

# Ship system enum. Matches to a dictionary.
enum ship_system_enum {
	NONE,
	BURN_DRIVE, # Order AI to turn it on if targeted_enemy_ship.BEHAVIOR_STATE  == FLEE and the local enemy is not superior.
	STEALTH, # Cuts sensor-profile to 5% for a long duration. Order AI to turn it on when just outside maximum enemy sensor range.
	PHASE, # Order AI to turn it on when a large amount of damage is incoming and flux is available.
	
}

var ship_system_dictionary: Dictionary = {
	#for copy pasting quickly ship_type_enum.RAPTOR : load(),
	ship_system_enum.STEALTH : load("res://Resources/ShipSystems/Stealth.tres"),
	}

#oooooo   oooooo     oooo oooooooooooo       .o.       ooooooooo.     .oooooo.   ooooo      ooo  .oooooo..o 
 #`888.    `888.     .8'  `888'     `8      .888.      `888   `Y88.  d8P'  `Y8b  `888b.     `8' d8P'    `Y8 
  #`888.   .8888.   .8'    888             .8"888.      888   .d88' 888      888  8 `88b.    8  Y88bo.      
   #`888  .8'`888. .8'     888oooo8       .8' `888.     888ooo88P'  888      888  8   `88b.  8   `"Y8888o.  
	#`888.8'  `888.8'      888    "      .88ooo8888.    888         888      888  8     `88b.8       `"Y88b 
	 #`888'    `888'       888       o  .8'     `888.   888         `88b    d88'  8       `888  oo     .d8P 
	  #`8'      `8'       o888ooooood8 o88o     o8888o o888o         `Y8bood8P'  o8o        `8  8""88888P'  
																										 
# PLEASE READ: Adding entries to the middle of an enum breaks everything else due to numbers being shifted. Godot's fault.
enum weapon_enum {
	AUTOCANNON = 0,
	CBEAM = 1,
	NIKEMISSILEMMEDIUM = 2,
	RAILGUN = 3,
	COMBATLASER = 4,
	NIKEMISSILE = 5,
	EMPTY = 6,
}

var weapon_dictionary: Dictionary = {
	weapon_enum.AUTOCANNON: load("res://Resources/Weapons/Medium/Autocannon.tres"),
	weapon_enum.CBEAM: load("res://Resources/Weapons/Medium/CBeam.tres"),
	weapon_enum.NIKEMISSILEMMEDIUM: load("res://Resources/Weapons/Medium/NikeMissileMedium.tres"),
	weapon_enum.RAILGUN: preload("res://Resources/Weapons/Small/Railgun.tres"),
	weapon_enum.COMBATLASER: load("res://Resources/Weapons/Small/CombatLaser.tres"),
	weapon_enum.NIKEMISSILE: load("res://Resources/Weapons/Small/NikeMissile.tres"),
	
	weapon_enum.EMPTY: preload("res://Resources/Weapons/EmptySlot.tres")
	}
	
# Nested Dictionary of (currently, weapons only) loadouts. Can make probalistic later and pair with ship mods/OP points.
var loadout_dictionary: Dictionary = {
	# Trident has 8 weapon slots
	ship_type_enum.TRIDENT: {
		loadout_enum.DEFAULT: [weapon_dictionary.get(weapon_enum.RAILGUN), 
			weapon_dictionary.get(weapon_enum.RAILGUN), 
			weapon_dictionary.get(weapon_enum.COMBATLASER),
			weapon_dictionary.get(weapon_enum.COMBATLASER), 
			weapon_dictionary.get(weapon_enum.CBEAM), 
			weapon_dictionary.get(weapon_enum.CBEAM),
			weapon_dictionary.get(weapon_enum.RAILGUN), 
			weapon_dictionary.get(weapon_enum.RAILGUN),
			]
	},
	ship_type_enum.CHALLENGER: {
		loadout_enum.DEFAULT: [weapon_dictionary.get(weapon_enum.RAILGUN), 
			weapon_dictionary.get(weapon_enum.RAILGUN), 
			weapon_dictionary.get(weapon_enum.RAILGUN),
			]
	},
	ship_type_enum.ECLIPSE: {
		loadout_enum.DEFAULT: [weapon_dictionary.get(weapon_enum.CBEAM), 
			weapon_dictionary.get(weapon_enum.CBEAM), 
			]
	}
}

var test_dictionary: Dictionary = {
	"a": weapon_dictionary.get(weapon_enum.RAILGUN),
}

enum weapon_mount_enum {
	SMALL_BALLISTIC,
	MEDIUM_BALLISTIC
}

var weapon_mount_dictionary: Dictionary = {
	#weapon_mount_enum.SMALL_BALLISTIC: load("res://Resources/WeaponMounts/SmallBallistic.tres"),
	#weapon_mount_enum.MEDIUM_BALLISTIC: load("res://Resources/WeaponMounts/MediumBallistic.tres"),
}

enum weapon_mount_type_enum {
	BALLISTIC,
	ENERGY,
	HYBRID,
	MISSILE,
	UNIVERSAL
}

enum size_enum {
	SMALL,
	MEDIUM,
	LARGE,
	SPINAL,
}

enum weapon_damage_enum {
	KINETIC,
	EXPLOSIVE,
	FRAGMENTATION,
	ENERGY,
	#UNIVERSAL
}

#oooooooooooo ooooo        oooooooooooo oooooooooooo ooooooooooooo  .oooooo..o 
#`888'     `8 `888'        `888'     `8 `888'     `8 8'   888   `8 d8P'    `Y8 
 #888          888          888          888              888      Y88bo.      
 #888oooo8     888          888oooo8     888oooo8         888       `"Y8888o.  
 #888    "     888          888    "     888    "         888           `"Y88b 
 #888          888       o  888       o  888       o      888      oo     .d8P 
#o888o        o888ooooood8 o888ooooood8 o888ooooood8     o888o     8""88888P'   
 

# To-Do: Rewrite weapon enums to item enums? 
enum item_enum {
	
	# Logistical/Usable Items
	SUPPLIES,
	FUEL,
	CREW,
	RESEARCH, 
	
	# Solely Commercial Items
	DRUGS,
	
	# Weapons: List from largest to smallest weapons for the purposes of sorting inventory, then by most expensive or rare first. Empty should always go last.
	AUTOCANNON,
	CBEAM,
	NIKEMISSILELAUNCHER,
	RAILGUN,
	COMBATLASER,
	NIKEMISSILE,
	EMPTY,
	
	# Fighters: follow the same principle as weapons. Expensive to cheap/common.
	RAPTOR,
	
}

# If it isn't in here, inventory won't work correctly.
var item_dictionary: Dictionary = {
	# Weapons
	item_enum.AUTOCANNON: weapon_dictionary.get(weapon_enum.AUTOCANNON),
	item_enum.CBEAM: weapon_dictionary.get(weapon_enum.CBEAM),
	item_enum.NIKEMISSILELAUNCHER: weapon_dictionary.get(weapon_enum.NIKEMISSILEMMEDIUM),
	item_enum.RAILGUN: weapon_dictionary.get(weapon_enum.RAILGUN),
	item_enum.COMBATLASER: weapon_dictionary.get(weapon_enum.COMBATLASER),
	item_enum.NIKEMISSILE: weapon_dictionary.get(weapon_enum.NIKEMISSILE),
	}

enum faction_enum {
	PLAYER,
	CHORAVEX,
	ZEALOTS,
	PIRATES, 
}
