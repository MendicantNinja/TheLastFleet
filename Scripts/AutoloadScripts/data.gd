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
	
	# Capitals (Suggestion: strong adjectives. Because capital ships do things. )
	ASTRAL,
	MALEVOLENT,
	
	
	#Motherships
}
var ship_type_dictionary: Dictionary = {
	#for copy pasting quickly ship_type_enum.RAPTOR : load(),
	# Fighters
	ship_type_enum.RAPTOR : load("res://ScriptsandResources/Resources/ShipHulls/Fighters/Raptor.tres"),
	
	# Frigates
	ship_type_enum.ISSUS: load("res://ScriptsandResources/Resources/ShipHulls/Frigates/Issus.tres"),
	
	# Destroyers
	ship_type_enum.LION : load("res://ScriptsandResources/Resources/ShipHulls/Destroyers/Lion.tres"),
	
	# Cruisers
	ship_type_enum.MARATHON: load("res://ScriptsandResources/Resources/ShipHulls/Cruisers/Marathon.tres"),
	
	# Capitals
	ship_type_enum.ASTRAL: load("res://ScriptsandResources/Resources/ShipHulls/Capitals/Astral.tres")
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
	ship_system_enum.STEALTH : load("res://ScriptsandResources/Resources/ShipSystems/Stealth.tres"),
	}

#oooooo   oooooo     oooo oooooooooooo       .o.       ooooooooo.     .oooooo.   ooooo      ooo  .oooooo..o 
 #`888.    `888.     .8'  `888'     `8      .888.      `888   `Y88.  d8P'  `Y8b  `888b.     `8' d8P'    `Y8 
  #`888.   .8888.   .8'    888             .8"888.      888   .d88' 888      888  8 `88b.    8  Y88bo.      
   #`888  .8'`888. .8'     888oooo8       .8' `888.     888ooo88P'  888      888  8   `88b.  8   `"Y8888o.  
	#`888.8'  `888.8'      888    "      .88ooo8888.    888         888      888  8     `88b.8       `"Y88b 
	 #`888'    `888'       888       o  .8'     `888.   888         `88b    d88'  8       `888  oo     .d8P 
	  #`8'      `8'       o888ooooood8 o88o     o8888o o888o         `Y8bood8P'  o8o        `8  8""88888P'  
																										 
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