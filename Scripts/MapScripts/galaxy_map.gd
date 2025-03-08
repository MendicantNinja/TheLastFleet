extends Node3D
class_name GalaxyMap

var galaxy_map_stats : GalaxyMapStats = GalaxyMapStats.new();
var selected_sector : Sprite3D = null;
@onready var sector_map = preload("res://Scenes/GameScenes/SectorMap.tscn");

func _input_mouse_moved(e: InputEventMouseMotion):
	var hits : Array[Sprite3D] = [];
	for i in $SectorBackbone.get_children():
		for j in i.get_children():
			if ($GalaxyMapCamera3D.get_screenspace(j) - e.global_position).length() < 100 * 1 / ($GalaxyMapCamera3D.global_position - j.global_position).length():
				#print("Hit!: ", ($GalaxyMapCamera3D.get_screenspace(j) - e.global_position).length());
				hits.append(j);
	
	var best_hit = null;
	var best_hit_dist = 40;
	if not hits.is_empty(): 
		for hit in hits:
			var dist = ($GalaxyMapCamera3D.get_screenspace(hit) - e.global_position).length();
			if dist < best_hit_dist:
				best_hit = hit;
				best_hit_dist = dist;
				
	selected_sector = best_hit;
	for i in $SectorBackbone.get_children():
		for j in i.get_children():
			if j == selected_sector: 
				j.scale = Vector3(0.13, 0.13, 0.13);
			else:
				j.scale = Vector3(0.1, 0.1, 0.1);
				
func _input_mouse_button(e: InputEventMouseButton):
	print("Clicking has not yet been implemented");
	

func _input(event): 
	if event is InputEventMouseMotion:
		_input_mouse_moved(event);
	if event is InputEventMouseButton:
		_input_mouse_button(event);
			

func _on_sector_button_pressed(i: int):
	game_state.player_fleet.fleet_stats.sector_id = i;
	print(galaxy_map_stats.sectors);
	var active_sector : SectorMap = galaxy_map_stats.sectors[i];
	var new = false;
	if active_sector == null:
		new = true;
		active_sector = sector_map.instantiate();
		galaxy_map_stats.sectors[i] = active_sector;
	$ActiveSector.add_child(active_sector);
	$ActiveSector.visible = true;
	if new:
		print("Generating New Sector")
		active_sector.call_deferred("randomize_stars");

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(8):
		var sector_button = Button.new();
		sector_button.text = "Sector %s" % i;
		sector_button.connect("pressed", _on_sector_button_pressed.bind(i));
		$Sectors.add_child(sector_button);
	
	$Load.connect("pressed", game_state.load_game);
	$Save.connect("pressed", game_state.save_game);
	$Generate.connect("pressed", generate_sectors);

func clear_sectors() -> void:
	for idx in range(1, 7):
		for child in $SectorBackbone.get_child(idx).get_children():
			child.queue_free();
			
func generate_sectors() -> void:
	clear_sectors();
	randomize_sectors();

func randomize_sectors() -> void:
	var total_node_count : int = 2;
	for idx in range(1, 7):
		var segment = $SectorBackbone.get_child(idx);
		var sector_count = randi() % 3 + 2;
		#if total_node_count + sector_count > 20:
			#
		var direction : Vector3 = ($SectorBackbone.get_child(idx + 1).global_position - $SectorBackbone.get_child(idx - 1).global_position).normalized().rotated(Vector3.UP, PI/2);
		for i in sector_count:
			var marker : Sprite3D = $MarkerPrototype.duplicate();
			segment.add_child(marker);
			#var offset = Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)) * direction / idx;
			#var offset = direction * randf_range(-2, 2) / idx;
			#var offset = direction * (sector_count - i);
			var offset = (direction * (sector_count - i) * 2 + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * 0.75 - direction * sector_count / 2 * 2) / (idx + 1);
			marker.global_position = segment.global_position + offset;
			marker.visible = true;
			marker.scale = $MarkerPrototype.scale;
			marker.name = str(i);
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	game_state.galaxy_map = self # FIXME!!! TEMPORARY!!!
	
	if Input.is_action_just_pressed("ui_cancel"):
		$ActiveSector.remove_child($ActiveSector.get_child(0));
		$ActiveSector.visible = false;
