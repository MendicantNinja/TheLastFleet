extends GridContainer
var ships_to_deploy: Array[ShipIcon]
@onready var CombatArena: Node2D = $"../../.."
@onready var PlayableAreaBounds = %PlayableAreaBounds
var fleet_deployment


var group_name: StringName = &"tomato"
var group_iterator: int = 0
# Deployment starts at the center-left, then walks right, with 300 pixels of space between each deployment position. 
# Has 3 rows and 7 columns (21 ships). Can be expanded later.
var deployment_position: Vector2
var deployment_row: int = 0
var deployment_spacing: int = 500
var combat_goal: int = 0
signal units_deployed(units)
signal deploy_ship(ship)

func _ready():
	%All.pressed.connect(on_all_pressed)
	%Cancel.pressed.connect(on_cancel_pressed)
	%Deploy.pressed.connect(deploy_ships)
	connect_buttons_lazy()
	pass

func connect_buttons_lazy() -> void:
	for child in $"../HBoxContainer".get_children():
		if child is TextureButton:
			child.pressed.connect(Callable(globals, "play_gui_audio_string").bind("confirm"))
			child.mouse_entered.connect(Callable(globals, "play_gui_audio_string").bind("hover"))

# Reset this when a ship moves off of it's deployment position.
func reset_deployment_position() -> void:
	# Start outside the map. Spawn ships starting at the top left quadrant of our 3 rowed, 7 columned rectangular ship formation.
	#					   ------- <- map boundary
	# starting position -> . . . . 
	# 					   . . . .
	# 					   . . . . <- ending position
	deployment_position.x = PlayableAreaBounds.shape.size.x/2 - deployment_spacing * 3 # 3+1+3 = 7 columns, start leftmost
	deployment_position.y = PlayableAreaBounds.shape.size.y + deployment_spacing * 2 # Start topmost row.
	#if settings.debug_mode == true:
		#deployment_position.y =  + deployment_spacing * 2
	deployment_row = 0

func on_icon_toggled(toggled_on: bool, this_icon: ShipIcon) -> void:
	if toggled_on == true:
		ships_to_deploy[this_icon.index] = this_icon
	elif toggled_on == false:
		ships_to_deploy[this_icon.index] = null

func deploy_ships() -> void:
	var check_flag: bool = false
	for ship_icon in ships_to_deploy:
		if ship_icon != null:
			if ship_icon.disabled == false:
				check_flag = true
				break
	if check_flag == false:
		on_cancel_pressed() # Hide menu after deploying ships
		return

	var instantiated_units: Array = []
	reset_deployment_position()
	var iterator: int = 0
	var n_group_name: StringName = group_name + str(group_iterator)
	var positions: Array = []
	var ship_positions: Dictionary = {}
	for ship_icon in ships_to_deploy:
		if ship_icon == null or ship_icon.disabled:
			continue
		var ship_instantiation: Ship = ship_icon.ship.ship_hull.ship_packed_scene.instantiate()
		ship_instantiation.collision_layer = 1
		ship_instantiation.initialize(ship_icon.ship)
		ship_icon.disabled = true
		deploy_ship.emit(ship_instantiation)
		instantiated_units.push_back(ship_instantiation)
		
		# Deployment Positioning
		if iterator % 7 == 0 and iterator != 0:
			deployment_row += 1
		# Iterator % 7. Iterator = 0-6 as remainder ( i == 6 == 7 ships). Then reset to 0 at iterator 7.
		ship_instantiation.global_position.x = deployment_position.x + iterator % 7 * deployment_spacing 
		ship_instantiation.global_position.y = deployment_position.y + deployment_spacing * deployment_row # I want to start at the top in terms of y
		positions.append(Vector2(ship_instantiation.global_position.x, ship_instantiation.global_position.y - deployment_spacing * 6 - deployment_spacing*deployment_row))
		ship_positions[ship_instantiation.global_position] = ship_instantiation
		ship_instantiation.posture = globals.Strategy.NEUTRAL
		ship_instantiation.add_to_group(&"friendly")
		ship_instantiation.group_add(n_group_name)
		iterator += 1
	group_iterator += 1
	var geo_median_ship: Vector2 = globals.geometric_median_of_objects(ship_positions.keys())
	var new_leader: Ship = globals.find_unit_nearest_to_median(geo_median_ship, ship_positions)
	var geo_median_formation: Vector2 = globals.geometric_median_of_objects(positions)
	geo_median_formation.x -= 1000
	geo_median_formation.y -= 2000
	new_leader.set_group_leader(true)
	new_leader.set_navigation_position(geo_median_formation)
	units_deployed.emit(instantiated_units) # Connects Unit Signals in TacticalMap
	imap_manager.RegisterAgents(instantiated_units, combat_goal)
	%TacticalDataDrawing.delayed_setup_call()
	
	#var TDD = %TacticalDataDrawing # Used for debugging ship_registry and deployed ships
	on_cancel_pressed() # Hide menu after deploying ships

func on_all_pressed() -> void:
	var excluding_deployed: Array[ShipIcon] = ships_to_deploy.duplicate()
	for ship_icon in excluding_deployed:
		if ship_icon == null:
			continue
		if ship_icon.disabled == true:
			excluding_deployed.erase(ship_icon)
	if excluding_deployed.has(null): # One of the not-yet deployed ships is unselected. so select everything
		for child in %FleetDeploymentList.get_children():
			if child.disabled == false:
				child.button_pressed = true
				on_icon_toggled(true, child)
			#if child.button_pressed == true:
				#child.button_pressed = false 
				#on_icon_toggled(false, child)
			else:
				continue
	elif excluding_deployed.has(null) == false: # All the not-yet deployed ships are selected, there is no "null" value anymore. Unselect everything.
		for child in %FleetDeploymentList.get_children():
			if child.disabled == false:
				child.button_pressed = false
				on_icon_toggled(false, child)
			else:
				continue

func on_cancel_pressed() -> void:
	%FleetDeploymentPanel.hide()

func setup_deployment_screen() -> void:
	# Add ships to the display and set the ship itself as item metadata.
	var scene_path = "res://Scenes/GUIScenes/CombatGUIScenes/GUIShipIcon.tscn"
	var gui_icon_scene = load(scene_path)
	ships_to_deploy.resize(game_state.player_fleet.fleet_stats.ships.size())
	for i in range(game_state.player_fleet.fleet_stats.ships.size()):
		var ship_icon: ShipIcon = gui_icon_scene.instantiate()
		self.add_child(ship_icon)
		ship_icon.on_added_to_container()
		ship_icon.ship = game_state.player_fleet.fleet_stats.ships[i]
		ship_icon.ship_sprite.texture_normal = ship_icon.ship.ship_hull.ship_sprite
		ship_icon.ship_label.text = str(ship_icon.ship.deployment_points)
		ship_icon.index = i
