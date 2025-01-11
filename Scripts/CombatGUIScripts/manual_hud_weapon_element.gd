extends GridContainer

var Number: RichTextLabel = null
var NameCount: RichTextLabel = null
var AutofireIndicator: TextureButton = null
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func initialize(weapon_system: WeaponSystem) -> void:
	Number = $Row1/Number
	NameCount = $Row1/NameCount
	AutofireIndicator = $Row1/AutofireIndicator
	Number.text = str(weapon_system.weapons[0].weapon_system_group+1)
	NameCount.text = weapon_system.weapons[0].weapon.weapon_name
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
