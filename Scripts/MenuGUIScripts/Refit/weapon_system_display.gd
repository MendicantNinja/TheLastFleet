extends GridContainer
@onready var WeaponDisplayRows: VBoxContainer = $"../WeaponDisplayRows"
@onready var weapon_row_scene: PackedScene = load("res://Scenes/GUIScenes/OtherGUIScenes/WeaponSystemRow.tscn")

# Update the Display of Weapons in the list based on the weapons that are currently equipped on the ship.
func update_weapon_systems(ship: Ship) -> void:
	# For the weapon system, make the appropriate autofires flick on.
	var iterator: int = 0
	for child in get_children():
		if child is TextureButton:
			child.weapon_system = ship.ship_stats.weapon_systems[iterator]
			if child.weapon_system.auto_fire_start == true:
				child.button_pressed = true
			else:
				child.button_pressed = false
			iterator += 1
	# Assigns weapons to the appropriate weapon system assignment.
	
	for child in WeaponDisplayRows.get_children():
		child.queue_free()
	
	for i in ship.all_weapons.size():
		if ship.all_weapons[i].weapon == data.weapon_dictionary.get(data.weapon_enum.EMPTY):
			continue
		var weapon_row_instance: HBoxContainer = weapon_row_scene.instantiate()
		weapon_row_instance.initialize(ship.ship_stats.weapon_slots[i])
		WeaponDisplayRows.add_child(weapon_row_instance)
		weapon_row_instance.AutofireLabel.custom_minimum_size = $AutofireLabel.custom_minimum_size
		
		# Populate the list

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#self.pressed.connect(self.on_button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
