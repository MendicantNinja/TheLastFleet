extends Node3D
class_name GalaxyMap

@export_storage var galaxy_map_stats : GalaxyMapStats = GalaxyMapStats.new();
var selected_sector : Sprite3D = null;
var inspected_sector : Sprite3D = null;
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
	if not e.pressed: return
	if selected_sector == null:
		# print("Clicked on nothing.");
		pass
	else:
		print("Clicked on ", selected_sector, "(sector ", selected_sector.get_parent().name, ", path ", selected_sector.name, ")");
		display_overlay(int(str(selected_sector.get_parent().name)), int(str(selected_sector.name)));
		# goto_sector_checked(int(str(selected_sector.get_parent().name)), int(str(selected_sector.name)))
	

func _input(event): 
	if event is InputEventMouseMotion:
		_input_mouse_moved(event);
	if event is InputEventMouseButton:
		_input_mouse_button(event);
			
			
func display_overlay(sector: int, choice: int):
	$SectorOverlay/SectorTitle.text = "[font_size=\"50px\"]Sector %d.%d[/font_size]" % [sector, choice];
	$SectorOverlay.visible = true;
	var trbtn: Button = $SectorOverlay/Travel;
	for conn in trbtn.get_incoming_connections():
		conn.signal.disconnect(conn.callable);
	
	trbtn.disabled = !valid_target(sector, choice);
	trbtn.connect("button_down", goto_sector.bind(sector, choice));
	if inspected_sector != null: 
		#inspected_sector.modulate = Color(0.659, 0.8, 1.0, 0.851);
		inspected_sector.material_override.emission = Color(1, 0, 0);
	inspected_sector = $SectorBackbone.get_child(sector).get_child(choice);
	#inspected_sector.modulate = Color(0, 0, 0, 0);
	inspected_sector.material_override = inspected_sector.material_override.duplicate(false);
	inspected_sector.material_override.emission = Color(0, 1, 0);

	
func valid_target(i: int, selection: int):
	return game_state.player_fleet.fleet_stats.sector_id == i - 1;
	

func goto_sector_checked(i: int, selection: int):
	if valid_target(i, selection):
		goto_sector(i, selection)
	else:
		print("Cannot travel from sector ", game_state.player_fleet.fleet_stats.sector_id, " to sector ", i)

func goto_sector(i: int, selection: int):
	game_state.player_fleet.fleet_stats.sector_id = i;
	galaxy_map_stats.selected_path.append(selection);
	#print(galaxy_map_stats.sectors);
	var active_sector : SectorMap = galaxy_map_stats.sectors[i];
	var new = false;
	if active_sector == null:
		new = true;
		active_sector = sector_map.instantiate();
		galaxy_map_stats.sectors[i] = active_sector;
	$ActiveSector.add_child(active_sector);
	$ActiveSector.modulate = Color(0, 0, 0, 0);
	$ActiveSector.visible = true;
	
	if new:
		print("New Sector Generated!")
	active_sector.call_deferred("randomize_stars");
		
	var tween = get_tree().create_tween();
	tween.set_parallel();
	
	tween.tween_property(
			$ActiveSector,
			"modulate",
			Color(1, 1, 1, 1),
			1,
		).set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_QUINT);
		
	tween.tween_property(
			$GalaxyMapCamera3D,
			"fov",
			0,
			1,
		).set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_QUINT);
		
	await tween.finished;
	
	draw_path();
	reset_visibility();
	
func draw_path():
	var verts = PackedVector3Array();
	for idx in range(len(galaxy_map_stats.selected_path)):
		var choice = galaxy_map_stats.selected_path[idx];
		verts.append($SectorBackbone.get_child(idx).get_child(choice).position);
		print("Drawing Line To ",
			$SectorBackbone.get_child(idx).get_child(choice),
			"(sector ",
			idx,
			", choice ",
			$SectorBackbone.get_child(idx).get_child(choice).name,
			")"
		);
		
	var arr_mesh = ArrayMesh.new();
	var arrays = [];
	arrays.resize(Mesh.ARRAY_MAX);
	arrays[Mesh.ARRAY_VERTEX] = verts;
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays);
	$Path.mesh = arr_mesh
	
		

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#for i in range(8):
		#var sector_button = Button.new();
		#sector_button.text = "Sector %s" % i;
		#sector_button.connect("pressed", goto_sector.bind(i));
		#$Sectors.add_child(sector_button);
	
	$Load.connect("pressed", func(): 
		game_state.load_game();
		generate_sectors();
		draw_path();
		reset_visibility();
	);
	$Save.connect("pressed", game_state.save_game);
	$Generate.connect("pressed", func(): 
		galaxy_map_stats.seed = randi();
		generate_sectors();
	);
	$DrawPath.connect("pressed", func():
		draw_path();
		reset_visibility();
	);
	
	generate_sectors();

func clear_sectors() -> void:
	for idx in range(1, 7):
		for child in $SectorBackbone.get_child(idx).get_children():
			child.queue_free();
			
func generate_sectors() -> void:
	print(galaxy_map_stats.seed);
	clear_sectors();
	await get_tree().process_frame
	await get_tree().process_frame
	randomize_sectors(galaxy_map_stats.seed);
	#call_deferred("randomize_sectors", galaxy_map_stats.seed);

func randomize_sectors(seed: int) -> void:
	var r = RandomNumberGenerator.new();
	r.seed = seed;
	var total_node_count : int = 2;
	for idx in range(1, 7):
		var segment = $SectorBackbone.get_child(idx);
		var sector_count = r.randi() % 3 + 2;
		#if total_node_count + sector_count > 20:
			#
		var direction : Vector3 = ($SectorBackbone.get_child(idx + 1).global_position - $SectorBackbone.get_child(idx - 1).global_position).normalized().rotated(Vector3.UP, PI/2);
		for i in sector_count:
			var marker : Sprite3D = $MarkerPrototype.duplicate();
			segment.add_child(marker);
			#var offset = Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)) * direction / idx;
			#var offset = direction * randf_range(-2, 2) / idx;
			#var offset = direction * (sector_count - i);
			var offset = (direction * (sector_count - i) * 2 + Vector3(r.randf_range(-1, 1), 0, r.randf_range(-1, 1)) * 0.75 - direction * sector_count / 2 * 2) / (idx + 1);
			marker.global_position = segment.global_position + offset;
			marker.visible = true;
			marker.scale = $MarkerPrototype.scale;
			marker.name = str(i);
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	game_state.galaxy_map = self # FIXME!!! TEMPORARY!!!
	
	if Input.is_action_just_pressed("ui_cancel"):
		$GalaxyMapCamera3D.fov = 125
		$ActiveSector.remove_child($ActiveSector.get_child(0));
		$ActiveSector.visible = false;
		

func reset_visibility():
	for sector in range(8):
		for choice in $SectorBackbone.get_child(sector).get_children():
			choice.visible = false;
			choice.material_override = load("res://Resources/Shaders/GalaxyMapMarkerPast.tres");
			
	for idx in range(len(galaxy_map_stats.selected_path)):
		var selection = galaxy_map_stats.selected_path[idx];
		var node = $SectorBackbone.get_child(idx).get_child(selection);
		node.visible = true;
		
	if game_state.player_fleet.fleet_stats.sector_id > 7:
		return;
	
	for opt in $SectorBackbone.get_child(game_state.player_fleet.fleet_stats.sector_id + 1).get_children():
		opt.material_override = load("res://Resources/Shaders/GalaxyMapMarker.tres");
		opt.visible = true;
		
