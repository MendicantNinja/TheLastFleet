extends HBoxContainer

var assigned_ship_data: ShipStats = null
var assigned_weapon_slot: WeaponSlot = null
@onready var AutofireLabel: RichTextLabel 
var button_group: ButtonGroup = ButtonGroup.new()
# Called when the node enters the scene tree for the first time.

func initialize(weapon_slot: WeaponSlot, ship_data: ShipStats) -> void:
	AutofireLabel = %AutofireLabel
	AutofireLabel.text = weapon_slot.weapon.weapon_name
	assigned_ship_data = ship_data
	assigned_weapon_slot = weapon_slot
	
	var iterator: int = 0
	if assigned_weapon_slot.weapon_system_group == -1:
		assigned_weapon_slot.weapon_system_group = 0
		assigned_ship_data.weapon_systems[assigned_weapon_slot.weapon_system_group].add_weapon(assigned_weapon_slot)
	for child in get_children():
		if child is TextureButton:
			child.weapon_system_number = iterator
			child.button_group = button_group
			if child.weapon_system_number == assigned_weapon_slot.weapon_system_group:
				child.button_pressed = true
			iterator += 1
	
	button_group.allow_unpress = false

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
