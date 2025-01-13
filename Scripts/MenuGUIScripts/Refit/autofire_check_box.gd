extends TextureButton

@onready var weapon_system: WeaponSystem = null
# Called when the node enters the scene tree for the first time.
func _ready():
	toggled.connect(on_button_toggled)
	pass # Replace with function body.

func on_button_toggled(toggled) -> void:
	weapon_system.auto_fire_start = toggled
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
