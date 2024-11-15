extends Node2D

@onready var CombatMap = $CombatMap
@onready var PlayableAreaBounds = $PlayableArea/PlayableAreaBounds
@onready var FleetDeploymentPanel = %FleetDeploymentPanel
@onready var FleetDeploymentList = %FleetDeploymentList
@onready var TacticalMap = %TacticalMap
@onready var All = %All
@onready var Deploy = %Deploy
@onready var Cancel = %Cancel

# Combat Camera
var camera_drag: bool = false
var zoom_in_limit: Vector2 = Vector2(0.5, 0.5)
var zoom_out_limit: Vector2 = Vector2(1.5, 1.5)
var zoom_value: Vector2 = Vector2.ONE

# groups
var available_group_names: Array[StringName] = [&"group A", &"group B", &"group C", &"group D"]
var taken_group_names: Array[StringName] = []
var tmp_group_name: StringName = &"temporary group"
var tmp_target_name: StringName = &"temporary target"

func _ready() -> void:
	TacticalMap.tmp_unit_select.connect(_on_tmp_unit_select)
	TacticalMap.move_unit.connect(_on_move_unit)
	TacticalMap.set_grid_parameters(PlayableAreaBounds.shape.size.x, PlayableAreaBounds.shape.size.y)
	TacticalMap.display_tactical_map()
	FleetDeploymentList.setup_deployment_screen()
	#settings.swizzle(FleetDeploymentList)
	settings.swizzle(FleetDeploymentPanel)
	settings.swizzle(All)
	settings.swizzle(Deploy)
	settings.swizzle(Cancel)
	var friendly_group: Array = get_tree().get_nodes_in_group("friendly")
	for friendly_ship in friendly_group:
		connect_ship_signals(friendly_ship)

func _unhandled_input(event) -> void:
	if event is InputEventKey:
		if (event.keycode == KEY_G and event.pressed):
			toggle_fleet_deployment_panel()
		elif (event.keycode == KEY_TAB and event.pressed):
			switch_maps()

func toggle_fleet_deployment_panel() -> void:
	if FleetDeploymentPanel.visible == false:
		FleetDeploymentPanel.visible = true
	else:
		FleetDeploymentPanel.visible = false

func switch_maps() -> void:
	CombatMap.display_combat_map()
	TacticalMap.display_tactical_map()

func make_group(n_group_name: StringName) -> void:
	get_tree().call_group(tmp_group_name, "group_add", n_group_name)
	get_tree().call_group(tmp_group_name, "group_remove", tmp_group_name)

func _on_tmp_unit_select(current_units: Array[Ship]) -> void:
	var current_group: Array = get_tree().get_nodes_in_group(tmp_group_name)
	if not current_group.is_empty():
		get_tree().call_group(tmp_group_name, "group_remove", tmp_group_name)
	
	for unit in current_units:
		var unit_groups: Array = unit.get_groups() # I hope and I pray and I cry and I bleed that ships are in two groups max
		if unit_groups.size() > 1:
			unit.remove_from_group(unit_groups[1])
		unit.add_to_group(tmp_group_name)

func _on_move_unit(to_position: Vector2) -> void:
	var current_group: Array = get_tree().get_nodes_in_group(tmp_group_name)
	if current_group.is_empty():
		return
	var unit_range: int = current_group.size() - 1
	var rand_group_leader: int = randi_range(0, unit_range)
	var new_group_name: StringName = available_group_names.pop_back()
	taken_group_names.push_back(new_group_name)
	make_group(new_group_name)
	current_group[rand_group_leader].set_group_leader(true)
	current_group[rand_group_leader].set_navigation_position(to_position)
	print(to_position)
	get_viewport().set_input_as_handled()

func _on_attack_targets(current_units: Array, target_units: Array) -> void:
	#_on_unit_select(current_units)
	var current_targets: Array = get_tree().get_nodes_in_group(tmp_target_name)
	if not current_targets.is_empty():
		get_tree().call_group(tmp_target_name, "group_remove", tmp_target_name)
	for target in target_units:
		target.add_to_group(tmp_target_name)

# Connect any signals at the start of the scene to ensure that all friendly and enemy ships
# are more than capable of signaling to each other changes in combat.
# Currently it only handles signals for friendly ships but it would take little to no effort to
# expand this for both. Ideally, we only use this to connect signals that are required for BOTH
# enemies and friendlies. 
func connect_ship_signals(friendly_ship: Ship) -> void:
	var enemy_group: Array = get_tree().get_nodes_in_group("enemy")
	for ship in enemy_group:
		ship.ship_targeted.connect(friendly_ship._on_ship_targeted)
