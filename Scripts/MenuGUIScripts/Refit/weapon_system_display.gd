extends GridContainer

# Update the Display of Weapons in the list based on the weapons that are currently equipped on the ship.
func update_weapon_systems(ship: Ship) -> void:
	# For the weapon system, make the appropriate autofires flick on.
	var iterator: int = 0
	for child in get_children():
		if child is TextureButton:
			child.weapon_system = ship.ship_stats.weapon_systems[iterator]
			iterator += 1
			
	# Assigns weapons to the appropriate weapon system assignment.
	for i in ship.all_weapons.size():
		pass
		# Populate the list

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#self.pressed.connect(self.on_button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
