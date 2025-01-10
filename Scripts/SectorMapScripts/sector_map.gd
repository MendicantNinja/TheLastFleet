extends Control

@export var columns = 6;
@export var rows = 4;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$GridContainer.columns = columns;
	for i in range(columns * rows):
		var st = preload("res://Scenes/CompositeGameObjects/Galaxy/StarTile.tscn").instantiate();
		st.name = str(i)
		$GridContainer.add_child(st);
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
