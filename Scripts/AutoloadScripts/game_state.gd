extends Node
# General save game that exports to a single file. 

var player_name: String = "Joe_Fleet"
var player_fleet: Fleet = Fleet.new()

func _ready():
	#for when user names are implemented ResourceLoader.load("user://"+get_child(0, true).text+".res")
	if player_fleet.fleet_stats.ships.is_empty():
		for i in range (10):
			if i % 100 == 0:
				player_fleet.add_ship(ShipStats.new(data.ship_type_enum.TRIDENT))
			elif i % 3 == 0:
				player_fleet.add_ship(ShipStats.new(data.ship_type_enum.ECLIPSE))
			else:
				player_fleet.add_ship(ShipStats.new(data.ship_type_enum.CHALLENGER))


# Saving/Loading the player and their fleet
func save_game() -> void:
	var save_me: SaveGame = SaveGame.new()
	save_me.save()

func load_game(fleet_name: String = "Joe_Fleet") -> void:
	var save_game: SaveGame = ResourceLoader.load("user://%s.res" % fleet_name)
	save_game.load()
# Saving/Loading the local state/scene tree (Solar Map)

# Saving/Loading the galactic state (GalaxyMap/FactionData). 
# Faction and Galactic Stats
