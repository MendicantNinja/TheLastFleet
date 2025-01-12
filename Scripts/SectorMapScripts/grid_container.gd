extends GridContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	columns = $"..".columns;
	var rows = $"..".rows;
	for i in range(columns * rows):
		var st = preload("res://Scenes/CompositeGameObjects/Galaxy/StarTile.tscn").instantiate();
		st.name = str(i);
		add_child(st);


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
