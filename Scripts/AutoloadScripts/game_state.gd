extends Node
# General stuff that exports to a single file. 
func save_game() -> void:
	pass

func load_game() -> void:
	pass

var player_name: String = "Joe_Fleet"
var player_fleet: Fleet #player_fleet.fleet_stats

func _ready():
	#for when user names are implemented ResourceLoader.load("user://"+get_child(0, true).text+".res")
	var save_game: SaveGame = ResourceLoader.load("user://Joe_Fleet.res")
	save_game.load()
	if player_fleet.fleet_stats.ships.is_empty():
		player_fleet = Fleet.new()
		for i in range (2):
			player_fleet.add_ship(ShipStats.new(data.ship_type_enum.TEST))

# Saving/Loading the player and their fleet

# Saving/Loading the local state/scene tree (Solar Map)

# Saving/Loading the galactic state (GalaxyMap/FactionData). 
# Faction and Galactic Stats

# Called when the node enters the scene tree for the first time.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
