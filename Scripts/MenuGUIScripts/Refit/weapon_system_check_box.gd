extends TextureButton

var weapon_system_number: int
# Called when the node enters the scene tree for the first time.
func _ready():
	toggled.connect(on_button_toggled)
	self.pressed.connect(Callable(globals, "play_gui_audio_string").bind("select"))
	#self.mouse_entered.connect(Callable(globals, "play_gui_audio_string").bind("hover"))
	pass # Replace with function body.

func on_button_toggled(toggled) -> void:
	if toggled == true:
		var assigned_ship_data: ShipStats = $"..".assigned_ship_data
		var assigned_weapon_slot: WeaponSlot = $"..".assigned_weapon_slot

		# Remove the weapon from its current system
		var current_weapon_system: WeaponSystem = assigned_ship_data.weapon_systems[assigned_weapon_slot.weapon_system_group]
		current_weapon_system.remove_weapon(assigned_weapon_slot)

		# Update the weapon system group of the slot
		assigned_weapon_slot.weapon_system_group = weapon_system_number

		# Add the weapon to the new system
		var new_weapon_system = assigned_ship_data.weapon_systems[weapon_system_number]
		new_weapon_system.add_weapon(assigned_weapon_slot)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
