extends Node2D

const CELL_CONTAINER_SCENE = preload("res://Scenes/CellContainer.tscn")

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
@onready var ImapDebug = $ImapDebug
@onready var ImapDebugGrid = $ImapDebug/ImapGridContainer

var debug_imap: bool = true
var influence_map: Imap
var imap_debug_grid: Array
#var local_influence_map: Imap

func _ready() -> void:
	process_mode = PROCESS_MODE_PAUSABLE
	TacticalMap.switch_maps.connect(_on_switch_maps)
	CombatMap.switch_maps.connect(_on_switch_maps)
	TacticalMap.set_grid_parameters(PlayableAreaBounds.shape.size.x, PlayableAreaBounds.shape.size.y)
	CombatMap.display_map(false)
	TacticalMap.display_map(true)
	
	var max_width: int = PlayableAreaBounds.shape.size.x
	var max_height: int = PlayableAreaBounds.shape.size.y
	var max_cell_size: int = 250
	influence_map = Imap.new(max_width, max_height, 0.0, 0.0, max_cell_size)
	
	if debug_imap == true:
		influence_map.update_grid_value.connect(_on_grid_value_changed)
		var grid_row_size: int = influence_map.map_grid.size()
		var grid_column_size: int = influence_map.map_grid[0].size()
		ImapDebug.size = PlayableAreaBounds.shape.size
		ImapDebugGrid.columns = grid_column_size
		for i in range(grid_row_size):
			imap_debug_grid.append([])
			for j in range(grid_column_size):
				var cell_instance: Container = CELL_CONTAINER_SCENE.instantiate()
				cell_instance.custom_minimum_size = Vector2.ONE * max_cell_size
				cell_instance.get_child(0).text = str(influence_map.get_cell_value(i, j))
				ImapDebugGrid.add_child(cell_instance)
				imap_debug_grid.append([cell_instance])
	
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
	pass
	#if get_tree().get_node_count_in_group(&"friendly") == 0 and ComputerAdmiral.AdmiralAI.enabled == true:
		#ComputerAdmiral.AdmiralAI.toggle_root(false)
	#if get_tree().get_node_count_in_group(&"friendly") > 0 and ComputerAdmiral.AdmiralAI.enabled == false:
		#ComputerAdmiral.AdmiralAI.toggle_root(true)

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

func _on_grid_value_changed(x, y, value) -> void:
	imap_debug_grid[x][y].get_child(0).text = str(value)

# Connect any signals at the start of the scene to ensure that all current friendly and enemy ships
# are more than capable of signaling to each other changes in combat.
# Ship targeted is moved over to the behavior tree but this function should ostensibly remain
# until it is clear this is no longer useful to us.
func connect_ship_signals(friendly_ship: Ship) -> void:
	#var enemy_group: Array = get_tree().get_nodes_in_group("enemy")
	#for ship in enemy_group:
		#ship.ship_targeted.connect(friendly_ship._on_ship_targeted)
	pass
