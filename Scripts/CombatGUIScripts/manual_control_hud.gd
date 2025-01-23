extends CanvasLayer

var current_ship: Ship = null

#Root Wrapper
@onready var HUDWrapper: Control = $HUDWrapper

# Weapon System Display Above
@onready var HardFluxIndicator = $HUDWrapper/HardFluxIndicator
@onready var SoftFluxIndicator = $HUDWrapper/HardFluxIndicator/SoftFluxIndicator
@onready var FluxPip = $HUDWrapper/HardFluxIndicator/FluxPip
@onready var HullIntegrityIndicator = $HUDWrapper/HullIntegrityIndicator


# Weapon System Display
@onready var IndicatorDecor = $HUDWrapper/IndicatorDecor
@onready var weapon_system_scene = load("res://Scenes/GUIScenes/CombatGUIScenes/ManualHUDWeaponElement.tscn")
@onready var weapon_system_scene_list: Array[GridContainer]
@onready var weapon_system_spacing: Vector2 = Vector2(62, 36)

# Proximity and Combat Radar
@onready var ship_registry: Array[Ship]
@onready var active_proximity_indicators: Dictionary = {}
@onready var ProxWarningContainer: Control = $HUDWrapper/ProxWarningContainer
@onready var proximity_indicator_max: int = 4000 #maximum allowable distnce
@onready var proximity_indicator_min: Vector2  = Vector2(2000, 1150) # minimum camera zoom approximation in pixels
@onready var proximity_indicator_icon = load("res://Scenes/GUIScenes/CombatGUIScenes/ProximityIndicator.tscn")
func set_ship(ship: Ship) -> void:
	print(ship)
	current_ship = ship
	if current_ship == null:
		self.visible = false
		return
	setup_ship_registry()
	setup_weapon_systems()
	update_hud()

func setup_ship_registry() -> void: 
	var ship_dictionary: Dictionary = imap_manager.registry_map
	var ship_arrays: Array = ship_dictionary.values()
	for array in ship_arrays:
		for ship in array:
			ship_registry.append(ship)
	

func _unhandled_key_input(event) -> void:
	if self.visible == true:
		if event.ctrl_pressed == true:
			if (event.keycode == KEY_1 and event.pressed):
				weapon_system_scene_list[0].toggle_autofire_pip()
			elif (event.keycode == KEY_2 and event.pressed):
				weapon_system_scene_list[1].toggle_autofire_pip()
			elif (event.keycode == KEY_3 and event.pressed):
				weapon_system_scene_list[2].toggle_autofire_pip()
			elif (event.keycode == KEY_4 and event.pressed):
				weapon_system_scene_list[3].toggle_autofire_pip()
			elif (event.keycode == KEY_5 and event.pressed):
				weapon_system_scene_list[4].toggle_autofire_pip()
			elif (event.keycode == KEY_6 and event.pressed):
				weapon_system_scene_list[5].toggle_autofire_pip()
			elif (event.keycode == KEY_7 and event.pressed):
				weapon_system_scene_list[6].toggle_autofire_pip()
			elif (event.keycode == KEY_8 and event.pressed):
				weapon_system_scene_list[7].toggle_autofire_pip()

func setup_weapon_systems() -> void:
	for child in $HUDWrapper.get_children():
		if child is GridContainer:
			child.queue_free()
	weapon_system_spacing = Vector2(62, 36)
	weapon_system_scene_list.clear()
	if current_ship == null:
		return
	for weapon_system in current_ship.weapon_systems:
		var weapon_system_instance: GridContainer = weapon_system_scene.instantiate()
		weapon_system_scene_list.append(weapon_system_instance)
		if weapon_system.weapons.is_empty() == false:
			weapon_system_instance.initialize(weapon_system)
			$HUDWrapper.add_child(weapon_system_instance)
			weapon_system_instance.position.x = IndicatorDecor.position.x + weapon_system_instance.gui_position.x
			weapon_system_instance.position.y =  IndicatorDecor.position.y + weapon_system_spacing.y
			weapon_system_spacing.y += weapon_system_instance.size.y + 5
	
	if weapon_system_spacing.y >= 36 + 25*6:
		$HUDWrapper.position.y -= 25
		$HUDWrapper/WeaponSystems.position.x += 4
		$HUDWrapper/WeaponSystems.position.y += 3
		IndicatorDecor.scale = Vector2(1.05, 1.25)
	elif weapon_system_spacing.y >= 36 + 25*7:
		print('holy shit thats alot of weapons')
		$HUDWrapper/WeaponSystems.position.x += 8
		$HUDWrapper/WeaponSystems.position.y += 6
		$HUDWrapper.position.y -= 50
		IndicatorDecor.scale = Vector2(1.1, 1.5)
	else: # May not be needed
		$HUDWrapper.position = Vector2(4, 1076)
		IndicatorDecor.scale = Vector2(1, 1)
		

func toggle_visible() -> void:
	if self.visible == true:
		self.visible = false
	elif self.visible == false:
		self.visible = true

func update_hud() -> void:
	if current_ship != null:
		self.visible = true
		var current_flux: float = current_ship.soft_flux + current_ship.hard_flux
		var flux_rate: float = 100 /  current_ship.total_flux # Returns a factor multiplier of the total flux that can be used to get a percentage. e.g 100/2000 = .05. 
		HardFluxIndicator.value = floor(flux_rate * current_ship.hard_flux)
		SoftFluxIndicator.value = floor(flux_rate * current_ship.soft_flux)
		SoftFluxIndicator.position.x = HardFluxIndicator.value
		FluxPip.position.x = HardFluxIndicator.value - 2
		
		HullIntegrityIndicator.max_value = current_ship.ship_stats.hull_integrity
		HullIntegrityIndicator.value = current_ship.hull_integrity
		
		# snatch ships from IMapManager, then display and modulate sprites and relative facing, then display and modulate ranges

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta) -> void:
	if Engine.get_physics_frames() % 4 == 0 and current_ship != null:
		# Create filtered list of ship positions and creare proximity indicators
		for ship in ship_registry:
			for child in ProxWarningContainer.get_children():
				child.queue_free()
			print("The current ship and queuered ships positions are", current_ship.position, ship.position)
			var diff: Vector2 = current_ship.global_position - ship.global_position  
			var distance: int = diff.length()
			var direction: Vector2 = diff.normalized()
			print("The diff and distance for this ship is ", diff, distance)
			if abs(diff.x) > proximity_indicator_min.x and abs(distance) < proximity_indicator_max or abs(diff.y) >= proximity_indicator_min.y and abs(distance) <= proximity_indicator_max:
				
				var proximity_indicator: Control = proximity_indicator_icon.instantiate()
				proximity_indicator.setup(ship)
				proximity_indicator.update_distance(Vector2(diff).length())
				
				ProxWarningContainer.add_child(proximity_indicator)
				# Direction
				print(direction.angle())
				proximity_indicator.position = get_screen_edge_intersection(direction)
				
				#var intersect: Vector2 = 
				#proximity_indicator.global_position = intersect
				#active_proximity_indicators[ship] = proximity_indicator
			#else:
				#if active_proximity_indicators.has(ship):
					#active_proximity_indicators.erase(ship)
		print(active_proximity_indicators.values().size())
		# Move these positions to where they need to go on the screen.
		# Create directional indicator

func get_screen_edge_intersection(normalized_vector: Vector2) -> Vector2:
	var screen_size: Vector2 = settings.screen_size
	var ship_position: Vector2 = settings.screen_size/2 # ship is centered on screen for the purposes of this calculation
	
	# 1920x1080 * .5
	# Our ship is at
	return Vector2()  # Return (0, 0) if no valid intersection found


func _process(delta):
	pass
		

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
