extends Node2D

const CELL_CONTAINER_SCENE = preload("res://Scenes/CellContainer.tscn")

@onready var CombatMap = $CombatMap
@onready var FleetDeploymentPanel = %FleetDeploymentPanel
@onready var FleetDeploymentList = %FleetDeploymentList
@onready var OptionsMenuPanel = %OptionsMenuPanel 
@onready var ManualControlHUD = %ManualControlHUD
@onready var TacticalMap = %TacticalMap
@onready var All = %All
@onready var Deploy = %Deploy
@onready var Cancel = %Cancel
@onready var PlayableAreaBounds = %PlayableAreaBounds
@onready var ComputerAdmiral = $Admiral
@onready var ImapDebug = $ImapDebug
@onready var ImapDebugGrid = $ImapDebug/ImapGridContainer

# Imap values and goodies
var debug_imap: bool = true
var imap_debug_grid: Array

func _ready() -> void:
	process_mode = PROCESS_MODE_PAUSABLE
	TacticalMap.switch_maps.connect(_on_switch_maps)
	CombatMap.switch_maps.connect(_on_switch_maps)
	TacticalMap.set_grid_parameters(PlayableAreaBounds.shape.size.x, PlayableAreaBounds.shape.size.y)
	CombatMap.display_map(false)
	TacticalMap.display_map(true)
	
	#occupancy_map = Imap.new(imap_manager.arena_width, imap_manager.arena_height, 0.0, 0.0, imap_manager.default_cell_size)
	#threat_map = Imap.new(imap_manager.arena_width, imap_manager.arena_height, 0.0, 0.0, imap_manager.default_cell_size)
	#occupancy_map.map_type = imap_manager.MapType.OCCUPANCY_MAP
	#threat_map.map_type = imap_manager.MapType.THREAT_MAP
	var influence_map: Imap = Imap.new(imap_manager.arena_width, imap_manager.arena_height, 0.0, 0.0, imap_manager.default_cell_size)
	var weighted_imap: Imap = Imap.new(imap_manager.arena_width, imap_manager.arena_height, 0.0, 0.0, imap_manager.default_cell_size)
	var fake_tension_map: Imap = Imap.new(imap_manager.arena_width, imap_manager.arena_height, 0.0, 0.0, imap_manager.default_cell_size)
	var tension_map: Imap = Imap.new(imap_manager.arena_width, imap_manager.arena_height, 0.0, 0.0, imap_manager.default_cell_size)
	var vulnerability_map = Imap.new(imap_manager.arena_width, imap_manager.arena_height, 0.0, 0.0, imap_manager.default_cell_size)
	influence_map.map_type = imap_manager.MapType.INFLUENCE_MAP
	weighted_imap.map_type = imap_manager.MapType.INFLUENCE_MAP
	fake_tension_map.map_type = imap_manager.MapType.TENSION_MAP
	vulnerability_map.map_type = imap_manager.MapType.VULNERABILITY_MAP
	tension_map.map_type = imap_manager.MapType.TENSION_MAP
	imap_manager.tension_map = tension_map
	imap_manager.vulnerability_map = vulnerability_map
	imap_manager.weighted_imap = weighted_imap
	var register_maps: Array = [influence_map, fake_tension_map]
	
	if debug_imap == true:
		vulnerability_map.update_grid_value.connect(_on_grid_value_changed)
		vulnerability_map.update_row_value.connect(_on_grid_row_changed)
		var grid_row_size: int = vulnerability_map.map_grid.size()
		var grid_column_size: int = vulnerability_map.map_grid[0].size()
		ImapDebug.size = PlayableAreaBounds.shape.size
		ImapDebugGrid.columns = grid_column_size
		for i in range(grid_row_size):
			imap_debug_grid.append([])
			for j in range(grid_column_size):
				var cell_instance: Container = CELL_CONTAINER_SCENE.instantiate()
				cell_instance.custom_minimum_size = Vector2.ONE * imap_manager.default_cell_size
				cell_instance.get_child(0).text = str(vulnerability_map.get_cell_value(i, j))
				cell_instance.get_child(0).visible = false
				ImapDebugGrid.add_child(cell_instance)
				imap_debug_grid[i].append(cell_instance)
	
	imap_manager.register_agents(get_tree().get_nodes_in_group(&"agent"))
	for map in register_maps:
		imap_manager.register_map(map)
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

func _on_grid_value_changed(m: int, n: int, value: float) -> void:
	var adj_value: float = snappedf(value, 0.001)
	if adj_value != 0.0:
		imap_debug_grid[m][n].get_child(0).visible = true
		imap_debug_grid[m][n].get_child(0).text = str(adj_value)
	else:
		imap_debug_grid[m][n].get_child(0).visible = false

func _on_grid_row_changed(m: int, value_array: Array) -> void:
	for n in range(0, value_array.size()):
		var adj_value: float = snappedf(value_array[n], 0.001)
		imap_debug_grid[m][n].get_child(0).text = str(adj_value)
		if adj_value == 0.0:
			imap_debug_grid[m][n].get_child(0).visible = false
		else:
			imap_debug_grid[m][n].get_child(0).visible = true

# Connect any signals at the start of the scene to ensure that all current friendly and enemy ships
# are more than capable of signaling to each other changes in combat.
# Ship targeted is moved over to the behavior tree but this function should ostensibly remain
# until it is clear this is no longer useful to us.
func connect_ship_signals(friendly_ship: Ship) -> void:
	#var enemy_group: Array = get_tree().get_nodes_in_group("enemy")
	#for ship in enemy_group:
		#ship.ship_targeted.connect(friendly_ship._on_ship_targeted)
	pass
