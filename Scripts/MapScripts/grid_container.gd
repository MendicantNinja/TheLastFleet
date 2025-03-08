extends GridContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	columns = $"..".columns;
	var rows = $"..".rows;
	for i in range(columns * rows):
		var st = preload("res://Scenes/CompositeGameObjects/Galaxy/StarTile.tscn").instantiate();
		st.name = str(i);
		add_child(st);
	for i in get_children():
		i.initialize();
		#i.randomize_star();


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func randomize_stars() -> void:
	for i in range($"..".columns * $"..".rows):
		get_child(i).randomize_star();
