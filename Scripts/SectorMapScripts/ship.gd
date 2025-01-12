extends TextureRect

@export var movement_factor = 0.1;
@export var offset = Vector2(20, 20);
@onready var target_position = position;
var current_idx;

func move_to_idx(idx: int) -> void:
	var current_star : Star = $"../GridContainer".get_child(current_idx).get_child(0);
	var target_star : Star = $"../GridContainer".get_child(idx).get_child(0);
	if idx in current_star.neighboring_tiles():
		current_idx = idx;
		target_position = target_star.global_position;
		
func move_to_idx_unchecked(idx: int) -> void:
	print("idx: ", idx);
	var target_star : Star = $"../GridContainer".get_child(idx).get_child(0);
	current_idx = idx;
	target_position = target_star.global_position;
	print(target_position)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#move_to_idx(0);
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = lerp(position, target_position + offset, movement_factor);
	target_position = $"../GridContainer".get_child(current_idx).get_child(0).global_position;
