extends Node2D

@onready var CombatMap = $CombatMap
@onready var FleetDeploymentPanel = %FleetDeploymentPanel
@onready var FleetDeploymentList = %FleetDeploymentList
@onready var OptionsMenuPanel = %OptionsMenuPanel 
@onready var TacticalMap = %TacticalMap
@onready var All = %All
@onready var Deploy = %Deploy
@onready var Cancel = %Cancel
@onready var PlayableAreaBounds = %PlayableAreaBounds
@onready var ComputerAdmiral = $Admiral

#var influence_map: Imap
#var local_influence_map: Imap

func _ready() -> void:
	TacticalMap.switch_maps.connect(_on_switch_maps)
	CombatMap.switch_maps.connect(_on_switch_maps)
	TacticalMap.set_grid_parameters(PlayableAreaBounds.shape.size.x, PlayableAreaBounds.shape.size.y)
	CombatMap.display_map(false)
	TacticalMap.display_map(true)
	
	var max_width: int = PlayableAreaBounds.shape.size.x
	var max_height: int = PlayableAreaBounds.shape.size.y
	var max_cell_size: int = 1000
	
	FleetDeploymentList.setup_deployment_screen()
	settings.swizzle(FleetDeploymentPanel)
	settings.swizzle(%OptionsMenuPanel)
	settings.swizzle(%MainMenuButton)
	settings.swizzle(All)
	settings.swizzle(Deploy)
	settings.swizzle(Cancel)
	#%BlackenBackground.size = PlayableAreaBounds.shape.size
	FleetDeploymentList.units_deployed.connect(TacticalMap.connect_unit_signals)
	var friendly_group: Array = get_tree().get_nodes_in_group("friendly")
	for friendly_ship in friendly_group:
		connect_ship_signals(friendly_ship)

func _process(delta) -> void:
	if get_tree().get_node_count_in_group(&"friendly") == 0 and ComputerAdmiral.AdmiralAI.enabled == true:
		ComputerAdmiral.AdmiralAI.toggle_root(false)
	if get_tree().get_node_count_in_group(&"friendly") > 0 and ComputerAdmiral.AdmiralAI.enabled == false:
		ComputerAdmiral.AdmiralAI.toggle_root(true)

func _unhandled_input(event) -> void:
	if event is InputEventKey:
		if (event.keycode == KEY_G and event.pressed):
			toggle_fleet_deployment_panel()
		if (event.keycode == KEY_ESCAPE and event.pressed):
			toggle_options_menu()

func toggle_fleet_deployment_panel() -> void:
	if FleetDeploymentPanel.visible == false:
		FleetDeploymentPanel.visible = true
	else:
		FleetDeploymentPanel.visible = false

func toggle_options_menu() -> void:
	if OptionsMenuPanel.visible == false:
		OptionsMenuPanel.visible = true
	else:
		OptionsMenuPanel.visible = false


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
# Ship targeted is moved over to the behavior tree but this function should ostensibly remain
# until it is clear this is no longer useful to us.
func connect_ship_signals(friendly_ship: Ship) -> void:
	#var enemy_group: Array = get_tree().get_nodes_in_group("enemy")
	#for ship in enemy_group:
		#ship.ship_targeted.connect(friendly_ship._on_ship_targeted)
	pass
