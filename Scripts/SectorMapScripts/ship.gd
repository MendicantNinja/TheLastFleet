extends Control

@export var movement_factor = 0.1;
@onready var target_position = position;
var current_idx = 0;

func _draw() -> void:
	pass

func move_to_idx(idx: int) -> void:
	var current_star : Star = $"../GridContainer".get_child(current_idx).get_child(0);
	var target_star : Star = $"../GridContainer".get_child(idx).get_child(0);
	if idx in current_star.get_parent().neighboring_tiles():
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = lerp(position, target_position, movement_factor);
	target_position = $"../GridContainer".get_child(current_idx).get_child(0).star_center;

	if (position - target_position).length() < 10:
		#print("Rotating!");
		rotation -= 0.02;
