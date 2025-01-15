extends Control
class_name LineOverlay

@onready var rows : int = $"../../..".rows;
@onready var cols : int = $"../../..".columns;
@onready var star : Star = $"../Star";
@onready var tile : ColorRect = get_parent();

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
		line.name = str(tile.name);
		
func _process(_delta: float) -> void:
	position = Vector2.ZERO;
	for line in get_children():
		var tile = $"../..".get_child(int(str(line.name)));
		line.points[0] = star.star_center - global_position;
		line.points[1] = tile.star.star_center - global_position;
