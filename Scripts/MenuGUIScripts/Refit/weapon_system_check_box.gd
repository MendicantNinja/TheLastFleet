extends TextureButton

var weapon_system_number: int
# Called when the node enters the scene tree for the first time.
func _ready():
	toggled.connect(on_button_toggled)
	
	pass # Replace with function body.

func on_button_toggled(toggled) -> void:
	if toggled == true:
		$"..".assigned_weapon_slot.weapon_system_group = weapon_system_number
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
