extends Node2D

@onready var CombatMap = $CombatMap
@onready var FleetDeploymentPanel = %FleetDeploymentPanel
@onready var FleetDeploymentList = %FleetDeploymentList
@onready var TacticalMap = %TacticalMap
@onready var All = %All
@onready var Deploy = %Deploy
@onready var Cancel = %Cancel
@onready var PlayableAreaBounds = %PlayableAreaBounds

# groups
var available_group_names: Array[StringName] = [&"group A", &"group B", &"group C", &"group D"]
var taken_group_names: Array[StringName] = []
var tmp_group_name: StringName = &"temporary group"
var tmp_target_name: StringName = &"temporary target"

func _ready() -> void:
	TacticalMap.switch_maps.connect(_on_switch_maps)
	CombatMap.switch_maps.connect(_on_switch_maps)
	TacticalMap.set_grid_parameters(PlayableAreaBounds.shape.size.x, PlayableAreaBounds.shape.size.y)
	CombatMap.display_map(false)
	TacticalMap.display_map(true)
	
	FleetDeploymentList.setup_deployment_screen()
	settings.swizzle(FleetDeploymentPanel)
	settings.swizzle(All)
	settings.swizzle(Deploy)
	settings.swizzle(Cancel)
	#%BlackenBackground.size = PlayableAreaBounds.shape.size
	var friendly_group: Array = get_tree().get_nodes_in_group("friendly")
	for friendly_ship in friendly_group:
		connect_ship_signals(friendly_ship)

func _unhandled_input(event) -> void:
	if event is InputEventKey:
		if (event.keycode == KEY_G and event.pressed):
			toggle_fleet_deployment_panel()

func toggle_fleet_deployment_panel() -> void:
	if FleetDeploymentPanel.visible == false:
		FleetDeploymentPanel.visible = true
	else:
		FleetDeploymentPanel.visible = false

func _on_switch_maps() -> void:
	if CombatMap.visible:
		CombatMap.display_map(false)
		TacticalMap.display_map(true)
	elif TacticalMap.visible:
		CombatMap.display_map(true)
		TacticalMap.display_map(false)
	
	get_viewport().set_input_as_handled()

# Connect any signals at the start of the scene to ensure that all current friendly and enemy ships
# are more than capable of signaling to each other changes in combat.
# Currently it only handles signals for friendly ships but it would take little to no effort to
# expand this for both. Ideally, we only use this to connect signals that are required for BOTH
# enemies and friendlies. 
func connect_ship_signals(friendly_ship: Ship) -> void:
	var enemy_group: Array = get_tree().get_nodes_in_group("enemy")
	for ship in enemy_group:
		ship.ship_targeted.connect(friendly_ship._on_ship_targeted)
