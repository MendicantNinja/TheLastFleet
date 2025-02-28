extends GridContainer
var ships_to_deploy: Array[ShipIcon]
@onready var CombatMap: Node2D = $"../../.."
@onready var PlayableAreaBounds = %PlayableAreaBounds
signal units_deployed(units)

# Deployment starts at the center-left, then walks right, with 300 pixels of space between each deployment position. 
# Has 3 rows and 7 columns (21 ships). Can be expanded later.
var friendly_deployment_position: Vector2
var friendly_deployment_row: int = 0
var friendly_deployment_spacing: int = 500

func _ready():
	%All.pressed.connect(self.on_all_pressed)
	%Cancel.pressed.connect(self.on_cancel_pressed)
	%Deploy.pressed.connect(self.deploy_ships)
	pass

# Reset this when a ship moves off of it's deployment position.
func reset_deployment_position() -> void:
	friendly_deployment_position.x = PlayableAreaBounds.shape.size.x/2 - friendly_deployment_spacing * 3 # 3+1+3 = 7 columns
	friendly_deployment_position.y = PlayableAreaBounds.shape.size.y - friendly_deployment_spacing * 3 # 3 rows
	friendly_deployment_row = 0

func on_icon_toggled(toggled_on: bool, this_icon: ShipIcon) -> void:
	if toggled_on == true:
		ships_to_deploy[this_icon.index] = this_icon
	elif toggled_on == false:
		ships_to_deploy[this_icon.index] = null

func deploy_ships() -> void:
	var instantiated_units: Array = []
	reset_deployment_position()
	var iterator: int
	for ship_icon in ships_to_deploy:
		if ship_icon == null or ship_icon.disabled:
			continue
		var ship_instantiation: Ship = ship_icon.ship.ship_hull.ship_packed_scene.instantiate()
		ship_instantiation.initialize(ship_icon.ship)
		ship_instantiation.is_friendly = true
		ship_icon.disabled = true
		CombatMap.add_child(ship_instantiation)
		instantiated_units.push_back(ship_instantiation)
		ship_instantiation.display_icon(true)
		
		# Deployment Positioning
		if iterator > 7:
			friendly_deployment_row += 1
		ship_instantiation.global_position.x = friendly_deployment_position.x + iterator * friendly_deployment_spacing # Correct
		ship_instantiation.global_position.y = friendly_deployment_position.y + friendly_deployment_spacing * 3 + 900 + friendly_deployment_row * friendly_deployment_spacing # I want to start at the top in termso f Y
		var path_to: Vector2 = Vector2(friendly_deployment_position.x + iterator * friendly_deployment_spacing, friendly_deployment_position.y - friendly_deployment_row * friendly_deployment_spacing)
		ship_instantiation.set_navigation_position(path_to)
		iterator += 1

	units_deployed.emit(instantiated_units) # Connects Unit Signals in TacticalMap
	imap_manager.register_agents(instantiated_units)
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
