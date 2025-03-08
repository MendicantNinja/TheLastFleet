extends Control

@export var movement_factor = 0.1;
@onready var target_position = position;
var current_idx = 0;

func _draw() -> void:
	pass

func valid_destinations(idx: int) -> Array:
	return $"../GridContainer".get_child(idx).get_node("LineOverlay").get_children() \
		.map(func(i): return int(str(i.name)));
	

func move_to_idx(idx: int) -> void:
	var current_star : Star = $"../GridContainer".get_child(current_idx).get_child(0);
	var target_star : Star = $"../GridContainer".get_child(idx).get_child(0);
	
	if idx in valid_destinations(current_idx):
		current_idx = idx;
		target_position = target_star.star_center;
		current_star.selected = false;
		target_star.selected = true;
		
func move_to_idx_unchecked(idx: int) -> void:
	var current_star : Star = $"../GridContainer".get_child(current_idx).get_child(0);
	var target_star : Star = $"../GridContainer".get_child(idx).get_child(0);
	current_idx = idx;
	target_position = target_star.star_center;
	current_star.selected = false;
	target_star.selected = true;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func initialize() -> void:
	var loaded_idx = game_state.player_fleet.fleet_stats.star_id;
	if loaded_idx == -1:
		move_to_idx_unchecked(int(str($"..".entrance.get_parent().name)));
	else:
		move_to_idx_unchecked(loaded_idx);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = lerp(position, target_position, movement_factor);
	target_position = $"../GridContainer".get_child(current_idx).get_child(0).star_center;
	
	var old = game_state.player_fleet.fleet_stats.star_id;
	game_state.player_fleet.fleet_stats.star_id = current_idx; # FIXME!! temporary spaghetti license acquired

	if current_idx != old:
		print("Changed player star_id from %s to %s." % [old, current_idx]);

	if (position - target_position).length() < 10:
		#print("Rotating!");
		rotation -= 0.02;
