extends TextureButton
class_name Star


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func neighboring_tiles() -> Array:
	var cols = $"../../..".columns;
	var rows = $"../../..".rows;
	var idx = int(str(get_parent().name));
	var neighboring_tiles = [
		idx - cols, # up
		idx + cols, # down
	];
	
	var neighboring_tiles_left = [
		idx - 1 + cols, # lower left
		idx - 1, # left
		idx - 1 - cols, # upper left
	];
	
	var neighboring_tiles_right = [
		idx + 1 - cols, # upper right
		idx + 1, # right
		idx + 1 + cols, # lower right
	];
	
	if idx % cols != 0: neighboring_tiles.append_array(neighboring_tiles_left);
	if idx % cols != 5: neighboring_tiles.append_array(neighboring_tiles_right);
	
	return neighboring_tiles;

	
func _on_mouse_entered() -> void:
	var cols = $"../../..".columns;
	var rows = $"../../..".rows;
	for tile in neighboring_tiles():
		if tile < 0 or tile >= cols * rows:
			continue;
		var target_startile = $"../..".get_child(tile);
		var start : Vector2 = global_position;
		var end : Vector2 = target_startile.get_child(0).global_position;
		var line : Line2D = Line2D.new();
		$"../../../LineOverlay".add_child(line);
		line.add_point(start - line.position);
		line.add_point(end - line.position);
		line.width = 3;
		line.position = Vector2(20, 20);
		line.default_color = Color.DARK_GREEN;
		
func _on_mouse_exited():
	for child in $"../../../LineOverlay".get_children():
		child.queue_free();


func _on_pressed() -> void:
	$"../../../Ship".move_to_idx(int(str(get_parent().name)));
