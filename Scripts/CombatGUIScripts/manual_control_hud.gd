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
@onready var OnScreenNotifier: VisibleOnScreenNotifier2D = %OnScreenNotifier
@onready var ProxWarningContainer: Control = $ProxWarningContainer
@onready var CombatCamera: Camera2D = $"../CombatMap/CombatCamera"
@onready var screen_size: Vector2 = settings.screen_size
@onready var proximity_indicator_max: int = 4500 #maximum allowable distnce
@onready var proximity_indicator_min: Vector2  = Vector2(screen_size.x/2, screen_size.y/2) # minimum camera zoom approximation in pixels
@onready var proximity_indicator_icon = load("res://Scenes/GUIScenes/CombatGUIScenes/ProximityIndicator.tscn")
func set_ship(ship: Ship) -> void:
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
	if Engine.get_physics_frames() % 5 == 0 and current_ship != null:
		# Create filtered list of ship positions and create proximity indicators
		var screen: Vector2 = screen_size #/ CombatCamera.zoom
		#if CombatCamera.zoom.x > 1:
			#screen = screen_size
		#print(CombatCamera.zoom)
		for child in ProxWarningContainer.get_children():
			child.free()
		for ship in ship_registry:
			var diff: Vector2 = ship.global_position - CombatCamera.global_position #current_ship.global_position
			var distance: int = diff.length()
			var direction: Vector2 = diff.normalized()
			
			if abs(diff.x) >= proximity_indicator_min.x and abs(distance) < proximity_indicator_max or abs(diff.y) >= proximity_indicator_min.y and abs(distance) <= proximity_indicator_max:
				#OnScreenNotifier.global_position = ship.global_position
				#if OnScreenNotifier.is_on_screen() == true:
					#return
				#print("Screen and diff is", screen, diff)
				var proximity_indicator: Control = proximity_indicator_icon.instantiate()
				proximity_indicator.setup(ship)
				#proximity_indicator.update_distance(distance)
				ProxWarningContainer.add_child(proximity_indicator)
				var right_boundary_intercept: bool = false
				var top_boundary_intercept: bool = false 
				var left_boundary_intercept: bool = false
				var bottom_boundary_intercept: bool = false
				if sign(direction.x) == 1:
					right_boundary_intercept = true
				elif sign(direction.x) == -1:
					left_boundary_intercept = true
				if sign(direction.y) == 1:
					bottom_boundary_intercept = true
				elif sign(direction.y) == -1:
					top_boundary_intercept = true
				# Determine right intersection position (if any)
					# y = .963, x = .265
				#var slope_x = 960 + screen.x/direction.x
				#var slope_y = 540 + screen.y/direction.y
				var right_intercept: int
				var left_intercept: int
				var top_intercept: int
				var bottom_intercept: int
				if right_boundary_intercept == true:
					right_intercept = (screen_size.x-(screen_size.x/2))/direction.x
					left_intercept = 10000
				if left_boundary_intercept == true:
					left_intercept = (0 - (screen_size.x/2))/direction.x
					right_intercept = 10000
				if top_boundary_intercept == true:
					top_intercept = (0 - (screen_size.y/2))/direction.y
					bottom_intercept = 10000
				if bottom_boundary_intercept == true:
					bottom_intercept = (screen_size.y - (screen_size.y/2))/direction.y
					top_intercept = 10000
				if direction.x == 0:
					right_intercept = 10000
					left_intercept = 10000
				if direction.y == 0:
					top_intercept = 10000
					bottom_intercept = 10000
				var intercept: Vector2 = Vector2(0, 0)
				var coordinate_1: int = min(right_intercept, left_intercept, bottom_intercept, top_intercept)
				var half_screen_distance: int
				var scale: float = diff.x/diff.y
				if coordinate_1 == right_intercept:
					intercept.x = screen_size.x
					intercept.y = screen_size.y/2+coordinate_1*direction.y
					var y_bonus: int = abs(screen_size.y/2+coordinate_1*direction.y) - ship.global_position.y  
					
					half_screen_distance = screen_size.x/2 #+ y_bonus #- abs(diff.y * (screen_size.x / screen_size.y)) #* CombatCamera.zoom.y #+ ( intercept.y/2 + CombatCamera.global_position.y )#960 + 
					if ship.global_position.x == 2340:
						print("y_bonus is", y_bonus)
						print("HSD, intercept.y, zoom, and distance is: ", half_screen_distance, "      ", diff.y, "      ", CombatCamera.zoom.y, "     ", distance - half_screen_distance)
						#print("diff direction and scale:  ", diff, "    ", direction, "     ", scale )
					proximity_indicator.position = Vector2(intercept.x - 40, intercept.y)
				elif coordinate_1 == left_intercept:
					intercept.x = 0
					intercept.y = screen_size.y/2+coordinate_1*direction.y
					half_screen_distance = screen_size.x/2
					proximity_indicator.position = Vector2(intercept.x, intercept.y)
				elif coordinate_1 == bottom_intercept:
					intercept.y = screen_size.y
					intercept.x = screen_size.x / 2 + coordinate_1 * direction.x
					half_screen_distance = screen_size.y/2
					# Flip text for bottom intercept to draw on top
					proximity_indicator.Distance.position = Vector2(6, -20)
					proximity_indicator.position = Vector2(intercept.x, intercept.y - 35)
				elif coordinate_1 == top_intercept:
					intercept.y = 0
					intercept.x = screen_size.x / 2 + coordinate_1 * direction.x
					half_screen_distance = screen_size.y/2
					proximity_indicator.position = Vector2(intercept.x, intercept.y)
				#var distance_mod: int = 2.05 * scale * (CombatCamera.global_position - ship.global_position).length() * CombatCamera.zoom.x - half_screen_distance
				proximity_indicator.update_distance((diff).length() * CombatCamera.zoom.x - half_screen_distance) # - (CombatCamera.global_position-intercept).length())
				#if ship.global_position.x == 2340:
					#print("Distance is", (CombatCamera.global_position - ship.global_position).length() * CombatCamera.zoom.x - half_screen_distance)

				#Vector2(0,screen_size.x/2)
				active_proximity_indicators[ship] = proximity_indicator
			#else:
				#if active_proximity_indicators.has(ship):
					#active_proximity_indicators.erase(ship)

func _process(delta):
	pass
		

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
