extends TextureButton

func _pressed() -> void:
	if $"..".assigned_ship == null:
		return
	if Input.is_action_pressed("alt_select"):
		$"..".assigned_ship.emit_signal("alt_select")
		return
	$"..".assigned_ship.toggle_ship_select()

# Called when the node enters the scene tree for the first time.

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
