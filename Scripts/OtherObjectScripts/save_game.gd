extends Resource
class_name SaveGame

@export var player_fleet_stats: FleetStats
@export var player_name: String
@export var player_sectors: Array[PackedScene]


#remove assignemnt operator later
#var save_game: SaveGame = ResourceLoader.load("user://Joe_Fleet.res")
#for when user names are implemented ResourceLoader.load("user://"+get_child(0, true).text+".res")
func save(image_to_save: ImageTexture = null) -> void:
	# Do what you need to do with player and NPC data (Will need to do a for loop later). 
	player_sectors = game_state.galaxy_map.galaxy_map_stats.pack();
	player_fleet_stats = game_state.player_fleet.fleet_stats
	player_name = game_state.player_name
	
	# Do what you need to do with the image. 
	#save_image = image_to_save
	
	#print("Saving star_id %s" % game_state.player_fleet.fleet_stats.star_id);
	
	# Save the save game resource itself
	if ResourceSaver.save(self, "user://%s.res" % player_name) != OK:
		print(player_name, " code ", ResourceSaver.save(self, "user://%s.res" % player_name), "save was unsuccessful")
	elif ResourceSaver.save(self, "user://%s.res" % player_name) == OK: 
		print("Saving of %s was successful " % player_name)
		ResourceSaver.save(self, "user://%s.res" % player_name)

func load() -> void:
	# Handle the data from the savegame class after calling ResourceLoader. Import them into the appropriate categories. 
	# Data for the player and NPC's.
	game_state.galaxy_map.galaxy_map_stats.unpack(player_sectors);
	game_state.player_fleet.fleet_stats = player_fleet_stats 
	game_state.player_name = player_name
	
	#print("Loading star_id %s" % game_state.player_fleet.fleet_stats.star_id);
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
