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

# List of Ships in the game. Matches to a dictionary.
enum ship_type_enum {
	# Fighters (Suggestion: Birds of Prey and Predatory Insects)
	RAPTOR,
	FALCON,
	
	# Frigates (Suggestion: Names of famous battles and reptiles/animals, famous animals?) 
	ISSUS,
	MONITOR, 
	
	# Destroyers (Suggestion: Pack animals and Tools. Famous commanders)
	LION,
	WOLF,
	
	# Cruisers (Suggestion: Nouns that are strong actions or suggest grand scale, so that they almost come off as verbs. )
	MARATHON, # Also the name of a famous battle! :D
	INFINITY, 
	
	# Capitals (Suggestion: strong adjectives. Because capital ships do things.)
	ASTRAL,
	MALEVOLENT,
	
	
	#Motherships
	
	# DEBUG / TEST SHIPS
	TEST,
}
var ship_type_dictionary: Dictionary = {
	#for copy pasting quickly ship_type_enum.RAPTOR : load(),
	# Fighters
	ship_type_enum.RAPTOR : load("res://Resources/ShipHulls/Fighters/Raptor.tres"),
	
	# Frigates
	ship_type_enum.ISSUS: load("res://Resources/ShipHulls/Frigates/Issus.tres"),
	
	# Destroyers
	ship_type_enum.LION : load("res://Resources/ShipHulls/Destroyers/Lion.tres"),
	
	# Cruisers
	ship_type_enum.MARATHON: load("res://Resources/ShipHulls/Cruisers/Marathon.tres"),
	
	# Capitals
	ship_type_enum.ASTRAL: load("res://Resources/ShipHulls/Capitals/Astral.tres"),
	
	# Test
	ship_type_enum.TEST: load("res://Resources/ShipHulls/TestHull.tres"),
}

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
																										 
enum weapon_enum {
	RAILGUN,
	EMPTY
}


var weapon_dictionary: Dictionary = {
	weapon_enum.RAILGUN: load("res://Resources/Weapons/Railgun.tres"),
	weapon_enum.EMPTY: preload("res://Resources/Weapons/EmptySlot.tres")
	}

enum weapon_mount_enum {
	SMALL_BALLISTIC,
	MEDIUM_BALLISTIC
}

var weapon_mount_dictionary: Dictionary = {
	weapon_mount_enum.SMALL_BALLISTIC: load("res://Resources/WeaponMounts/SmallBallistic.tres"),
	weapon_mount_enum.MEDIUM_BALLISTIC: load("res://Resources/WeaponMounts/MediumBallistic.tres"),
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
	RAILGUN,
	EMPTY,
	
	# Fighters: follow the same principle as weapons. Expensive to cheap/common.
	RAPTOR,
	
}

var item_dictionary: Dictionary = {
	item_enum.RAILGUN: preload("res://Resources/Weapons/Railgun.tres"),
	}

enum faction_enum {
	PLAYER,
	CHORAVEX,
	ZEALOTS,
	PIRATES, 
	
}

#ooooooooooooo oooooooooooo ooooooo  ooooo ooooooooooooo 
#8'   888   `8 `888'     `8  `8888    d8'  8'   888   `8 
	 #888       888            Y888..8P         888      
	 #888       888oooo8        `8888'          888      
	 #888       888    "       .8PY888.         888      
	 #888       888       o   d8'  `888b        888      
	#o888o     o888ooooood8 o888o  o88888o     o888o     	

enum sector_type_enum {
	HUMAN = 0,
	CHORAVEX = 1,
	ZEALOTS = 2,
	PIRATES = 3,
	NEBULA = 4,
}

var localization_dictionary: Dictionary = {
	# Random names
	&"first": {
	sector_type_enum.HUMAN: [
		"Arcturus",
		"Vanguard",
		"Epsilon",
		"Newport",
		"Helios",
		"Solace",
		"Frontier",
		"Colossus",
		"Avalon",
		"Unity",
		"Orion",
		"Halberd",
		"Draco",
		"Bastion",
		"Pioneer"
	],
	sector_type_enum.NEBULA: [
		"Velora",
		"Myrrh",
		"Aether",
		"Ossian",
		"Nyx",
		"Zephyr",
		"Thalassa",
		"Lorien",
		"Virel",
		"Cinder",
		"Eidolon",
		"Noctis",
		"Mira",
		"Caelum",
		"Ysil"
	],
		},
	
	&"last": {
		sector_type_enum.HUMAN:
		["Group", "Cluster", "Sector", "Expanse"],
		sector_type_enum.NEBULA:
		["Nebula", "Shroud", "Cloud"],
	# Text/Names of common terms. E.g. "hull", "flux"
		},
	&"flux": "flux",
	# Relatively unique 1-off buttons "New Game, Load Game"
	
	
	
}

func generate_random_name(p_sector_type: sector_type_enum) -> Array[String]: # Returns first and last name
	var sector_type: sector_type_enum = p_sector_type
	var first_name: String
	# We don't want to have different names for alien sectors, yet.
	if sector_type != sector_type_enum.HUMAN or  sector_type != sector_type_enum.NEBULA:
		sector_type = sector_type_enum.HUMAN
	var first_name_array: Array[String] = localization_dictionary.get(&"first").get(sector_type)
	first_name = first_name_array.pick_random()
	
	
	var last_name: String
	if sector_type != sector_type_enum.HUMAN or  sector_type != sector_type_enum.NEBULA:
		sector_type = sector_type_enum.HUMAN
	var last_name_array: Array[String] = localization_dictionary.get(&"last").get(sector_type)
	last_name = last_name_array.pick_random()
	return [first_name, last_name]
	
func get_text(string_key: String) -> String:
	return localization_dictionary.get(string_key)
	#localization_dictionary.find_key()




#ooooooooooooo       .o.       oooooooooo.  ooooo        oooooooooooo  .oooooo..o 
#8'   888   `8      .888.      `888'   `Y8b `888'        `888'     `8 d8P'    `Y8 
	 #888          .8"888.      888     888  888          888         Y88bo.      
	 #888         .8' `888.     888oooo888'  888          888oooo8     `"Y8888o.  
	 #888        .88ooo8888.    888    `88b  888          888    "         `"Y88b 
	 #888       .8'     `888.   888    .88P  888       o  888       o oo     .d8P 
	#o888o     o88o     o8888o o888bood8P'  o888ooooood8 o888ooooood8 8""88888P'  
																				 
																																	 
