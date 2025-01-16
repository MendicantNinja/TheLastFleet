extends Control
class_name GalaxyMap

var galaxy_map_stats : GalaxyMapStats = GalaxyMapStats.new();
@onready var sector_map = preload("res://Scenes/GameScenes/SectorMap.tscn");

func _on_sector_button_pressed(i: int):
	game_state.player_fleet.fleet_stats.sector_id = i;
	var active_sector : SectorMap = galaxy_map_stats.sectors[i];
	var new = false;
	if active_sector == null:
		new = true;
		active_sector = sector_map.instantiate();
		galaxy_map_stats.sectors[i] = active_sector;
	$ActiveSector.add_child(active_sector);
	$ActiveSector.visible = true;
	if new:
		active_sector.call_deferred("randomize_stars");
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(8):
		var sector_button = Button.new();
		sector_button.text = "Sector %s" % i;
		sector_button.connect("pressed", _on_sector_button_pressed.bind(i));
		$Sectors.add_child(sector_button);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	game_state.galaxy_map = self # FIXME!!! TEMPORARY!!!
