extends Control

@export var padding = 30;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var max_x : int = get_viewport_rect().size.x - padding * 2;
	var max_y : int = get_viewport_rect().size.y - padding * 2;
	
	$Star.position = Vector2(
		randi() % (max_x / 6 - padding), 
		randi() % (max_y / 6 - padding)
	) + position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
