extends Control
class_name LineOverlay

@onready var rows : int = $"../../..".rows;
@onready var cols : int = $"../../..".columns;
@onready var star : Star = $"../Star";

@export var line_prototype : Line2D;

func initialize():
	for tile_idx in star.get_parent().neighboring_tiles():
		if tile_idx < 0 or tile_idx >= cols * rows:
			continue;
		var line = line_prototype.duplicate();
		var tile = $"../..".get_child(tile_idx);
		add_child(line)
		line.visible = true;
		line.points[0] = star.star_center - position;
		line.points[1] = tile.star.star_center - position;
		line.name = str(tile_idx);
		
func _process(_delta: float) -> void:
	position = Vector2.ZERO;
	# pretty, but gets in the way of gameplay since A > B no longer guarantees B > A
	#var max_length = 0;
	#for line in get_children():
		#if line in $"..".diagonal_neighboring_tiles(): continue
		#max_length = max((line.points[0] - line.points[1]).length(), max_length);
	#if max_length == 0: return;
		
	for line in get_children():
		var idx = int(str(line.name));
		var tile = $"../..".get_child(idx);
		line.points[0] = star.star_center - global_position;
		line.points[1] = tile.star.star_center - global_position;
		var line_length = (line.points[0] - line.points[1]).length();
		if line_length > 300 and idx in $"..".diagonal_neighboring_tiles():
			line.queue_free();
