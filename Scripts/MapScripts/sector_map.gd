extends Control
class_name SectorMap

@export var columns = 6;
@export var rows = 4;

@export var entrance_row = -1;
@export var exit_row = -1;

@export var entrance: Star;
@export var exit: Star;

@export var label_offset = Vector2(5, 10);

func get_star_xy(x: int, y: int) -> Star:
	return get_star_id(x % columns + (y % rows) * columns);
	
func get_star_id(id: int) -> Star:
	return $GridContainer.get_child(id % (rows * columns)).get_child(0);


# Called when the node enters the scene tree for the first time.
func _init() -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	entrance_row = (randi() if entrance_row < 0 else entrance_row) % rows;
	exit_row = (randi() if exit_row < 0 else exit_row) % rows;
	
	entrance = get_star_xy(0, entrance_row);
	exit = get_star_xy(columns - 1, exit_row);
	
	#$Ship.move_to_idx_unchecked(int(str(entrance.get_parent().name)));
	
func randomize_stars() -> void:
	$GridContainer.randomize_stars();
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$EntranceStar.global_position = entrance.star_center + label_offset;
	$ExitStar.global_position = exit.star_center + label_offset;
