extends TextureButton
# Called when the node enters the scene tree for the first time.
func _ready():
	var binding_name = globals.convert_input_to_string(&"exit_manual_control", "red")
	$Keybinding.text = binding_name
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
