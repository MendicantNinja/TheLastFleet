extends GridContainer
var ships_to_deploy: Array[ShipIcon]
@onready var CombatMap: Node2D = $"../../.."

func _ready():
	%All.pressed.connect(self.on_all_pressed)
	%Cancel.pressed.connect(self.on_cancel_pressed)
	%Deploy.pressed.connect(self.deploy_ships)
	pass

func on_icon_toggled(toggled_on: bool, this_icon: ShipIcon) -> void:
	if toggled_on == true:
		ships_to_deploy[this_icon.index] = this_icon
	elif toggled_on == false:
		ships_to_deploy[this_icon.index] = null

func deploy_ships() -> void:
	for ship_icon in ships_to_deploy:
		if ship_icon == null or ship_icon.disabled:
			continue
		var ship_instantiation: Ship = ship_icon.ship.ship_hull.ship_packed_scene.instantiate()
		ship_instantiation.initialize(ship_icon.ship)
		ship_instantiation.global_position = Vector2(500, 500)
		ship_instantiation.is_friendly = true
		ship_icon.disabled = true
		CombatMap.add_child(ship_instantiation)
		CombatMap.ships_in_combat.append(ship_instantiation)
	on_cancel_pressed()

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
