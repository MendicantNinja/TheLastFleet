extends Control

@export var padding = 30;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var max_x : int = get_viewport_rect().size.x - padding * 2;
	var max_y : int = get_viewport_rect().size.y - padding * 2;
	
	var cols = $"../..".columns;
	var rows = $"../..".rows;
	
	$Star.position = Vector2(
		randi() % (max_x / cols - padding), 
		randi() % (max_y / rows - padding)
	) + position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
