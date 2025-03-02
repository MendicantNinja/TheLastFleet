extends Node

enum Strategy{
	NEUTRAL,
	DEFENSIVE,
	OFFENSIVE,
	EVASIVE
}

enum GOAL{
	SKIRMISH,
	MOTHERSHIP,
	CONTROL,
}

func play_audio_pitched(sound: AudioStream, position: Vector2 ) -> void:
	# Universal Setup
	var audio_stream_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	audio_stream_player.autoplay = true
	audio_stream_player.pitch_scale = audio_stream_player.pitch_scale * randf_range(.80, 1.2)
	#audio_stream_player.max_distance = 1600
	# Variable Setup
	audio_stream_player.stream = sound #randomize later on if we do multiple samples
	audio_stream_player.position = position
	audio_stream_player.volume_db = settings.sound_effect_volume
	
	add_child(audio_stream_player)
	audio_stream_player.finished.connect(audio_stream_player.queue_free)

# Useful for displaying hotkeys, especially ones the player has given a custom binding.
func convert_input_to_string(action: StringName, color: String = "orange", use_custom_color: bool = false) -> String:
	var custom_binding: InputEventKey = InputMap.action_get_events(action)[0] # If multiple inputs bound, grab the first input for display
	var readable: String = OS.get_keycode_string(custom_binding.get_physical_keycode_with_modifiers())
	var returned_bbcode: String = "[color=" + color + "]"+ readable + "[/color]"
	if use_custom_color == true:
		returned_bbcode = "[color=#%s]%s[/color]" % [settings.gui_color.to_html(), readable]
	return returned_bbcode

func geometric_median_of_objects(object_positions: Array, epsilon: float = 1e-5) -> Vector2:
	var sum_x: float = 0.0
	var sum_y: float = 0.0
	var number_of_objects: int = object_positions.size()
	for position in object_positions:
		sum_x += position.x
		sum_y += position.y
	
	var median: Vector2 = Vector2(sum_x / number_of_objects, sum_y / number_of_objects)
	var new_median: Vector2 = median
	var euclidean_distance: float = 1.0
	while euclidean_distance > epsilon:
		var distances: Dictionary = {}
		for position: Vector2 in object_positions:
			distances[position] = position.distance_to(median)
		
		var non_zero_distances: Dictionary = {}
		for position in distances.keys():
			var n_distance: float = distances[position]
			if n_distance != 0.0:
				non_zero_distances[position] = n_distance
		
		if non_zero_distances.is_empty():
			break
		
		var weighted_sum_x: float = 0.0
		var weighted_sum_y: float = 0.0
		var weights: float = 0.0
		for position in non_zero_distances.keys():
			var n_distance: float = non_zero_distances[position]
			weighted_sum_x += position.x / n_distance
			weighted_sum_y += position.y / n_distance
			weights += 1 / n_distance
		
		var test_median: Vector2 = Vector2(weighted_sum_x / weights, weighted_sum_y / weights)
		if test_median == new_median:
			break
		
		new_median = Vector2(weighted_sum_x / weights, weighted_sum_y / weights)
		euclidean_distance = new_median.distance_to(median)
	
	median = new_median
	return median

func find_unit_nearest_to_median(median: Vector2, unit_positions: Dictionary):
	var nearest_unit = null
	var distances_to_median: Dictionary = {}
	for position in unit_positions:
		var unit = unit_positions[position]
		var distance_to: float = position.distance_to(median)
		distances_to_median[distance_to] = unit
	
	var min_distance: float = distances_to_median.keys().min()
	nearest_unit = distances_to_median[min_distance]
	return nearest_unit


func reset_group_leader(unit: Ship) -> void:
	var group: Array = get_tree().get_nodes_in_group(unit.group_name)
	var new_leader = null
	var leader_key = &"leader"
	if group.size() > 0 and group.size() <= 2:
		new_leader = group[0]
	elif group.size() > 2:
		var unit_positions: Dictionary = {}
		for n_unit in group:
			unit_positions[n_unit.global_position] = n_unit
		
		var median: Vector2 = geometric_median_of_objects(unit_positions.keys())
		new_leader = find_unit_nearest_to_median(median, unit_positions)
	
	get_tree().call_group(unit.group_name, &"set_blackboard_data", leader_key, new_leader)
	# maybe shift orders to new leader here
	
	if not unit.ShipNavigationAgent.is_navigation_finished():
		var distance_to_position: float = unit.position.distance_to(unit.target_position)
		var angle_to_position: float = unit.position.angle_to(unit.target_position)
		var rotate_direction: Vector2 = new_leader.transform.x.rotated(angle_to_position)
		var delta_position: Vector2 = rotate_direction * distance_to_position
		var relative_position: Vector2 = new_leader.position + delta_position
		new_leader.set_group_leader(true)
		new_leader.set_navigation_position(relative_position)
	unit.set_group_leader(false)

@warning_ignore("integer_division")
func generate_group_target_positions(leader: Ship) -> void:
	var group: Array = get_tree().get_nodes_in_group(leader.group_name)
	var occupancy_sizes: Array = []
	var average_size: Vector2 = Vector2.ZERO
	var unit_positions: Dictionary = {}
	for unit: Ship in group:
		unit_positions[unit.global_position] = unit
		var size: float = unit.template_maps[imap_manager.MapType.OCCUPANCY_MAP].width - 1
		occupancy_sizes.append(size)
		average_size += Vector2(size, size)
	
	average_size /= group.size()
	var max_size: int = occupancy_sizes.max()
	var min_size: int = occupancy_sizes.min()
	var unit_separation: Vector2 = Vector2.ZERO
	if max_size == min_size and (leader.posture == Strategy.DEFENSIVE or leader.posture == Strategy.NEUTRAL):
		unit_separation = Vector2(average_size.x, average_size.y) * (imap_manager.default_cell_size / 2)
	
	var geo_mean: Vector2 = Vector2.ZERO
	var offsets: Array = []
	if leader.posture == Strategy.DEFENSIVE or leader.posture == Strategy.NEUTRAL:
		var radius: int = ceil(sqrt(group.size()))
		offsets = box_formation_offset_positions(leader, radius, unit_separation)
		geo_mean = geometric_median_of_objects(offsets)
	
	unit_positions.clear()
	for unit in group:
		var distance_to: float = geo_mean.distance_to(unit.global_position)
		unit_positions[distance_to] = unit
	
	var sort_positions: Array = unit_positions.keys()
	sort_positions.sort()
	# get geo mean of offset positions
	# iterate through units to get furthest from geo mean
	var visited: Array = []
	for i in range(sort_positions.size() - 1, -1, -1):
		var dist: float = sort_positions[i]
		var unit: Ship = unit_positions[dist]
		var slot_distances: Dictionary = {}
		for slot in offsets:
			if slot in visited:
				continue
			var distance_to: float = unit.global_position.distance_to(slot)
			slot_distances[distance_to] = slot
		var min_dist: float = slot_distances.keys().min()
		var target_position: Vector2 = slot_distances[min_dist]
		unit.target_position = target_position
		print(unit.name, unit.target_position)
		visited.append(target_position)
		if visited.size() == group.size():
			return

@warning_ignore("narrowing_conversion", "integer_division")
func box_formation_offset_positions(leader, radius, separation) -> Array:
	var target_position: Vector2 = leader.target_position
	var offsets: Array = [] 
	for m in range(0, radius * separation.y, separation.y):
		for n in range(0, radius * separation.x, separation.x):
			var pos: Vector2 = Vector2(target_position.x + n, target_position.y + m)
			offsets.append(pos)
			if offsets.size() >= get_tree().get_node_count_in_group(leader.group_name):
				return offsets
	return offsets
	
#func box_formation(leader: Ship, radius: int, slot_distance: int) -> Array:
	#var target_cell: Vector2i = Vector2i(leader.target_position.y / imap_manager.default_cell_size, leader.target_position.x / imap_manager.default_cell_size)
	#var iter_distance: int = slot_distance + 1
	#var slots: Array = []
	#for m in range(-radius, radius, iter_distance):
		#var target_m: int = target_cell.x - m
		#for n in range(-radius, radius, iter_distance):
			#var target_n: int = target_cell.y - n
			#var cell: Vector2i = Vector2i(target_m, target_n)
			#if cell == target_cell:
				#continue
			#slots.append(cell)
	#return slots

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
