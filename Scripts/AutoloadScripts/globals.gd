extends Node

enum Strategy{
	NEUTRAL,
	DEFENSIVE,
	OFFENSIVE,
	EVASIVE
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
	if group.size() > 0 and group.size() <= 2:
		new_leader = group[0]
	elif group.size() > 2:
		var unit_positions: Dictionary = {}
		for n_unit in group:
			unit_positions[n_unit.global_position] = n_unit
		
		var median: Vector2 = geometric_median_of_objects(unit_positions.keys())
		new_leader = find_unit_nearest_to_median(median, unit_positions)
	
	if not unit.ShipNavigationAgent.is_navigation_finished():
		var distance_to_position: float = unit.position.distance_to(unit.target_position)
		var angle_to_position: float = unit.position.angle_to(unit.target_position)
		var rotate_direction: Vector2 = new_leader.transform.x.rotated(angle_to_position)
		var delta_position: Vector2 = rotate_direction * distance_to_position
		var relative_position: Vector2 = new_leader.position + delta_position
		new_leader.set_group_leader(true)
		new_leader.set_navigation_position(relative_position)
	unit.set_group_leader(false)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
