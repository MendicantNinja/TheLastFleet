extends Node2D

const CELL_CONTAINER_SCENE = preload("res://Scenes/CellContainer.tscn")

@onready var CombatMap = $CombatMap
@onready var FleetDeploymentPanel = %FleetDeploymentPanel
@onready var FleetDeploymentList = %FleetDeploymentList
@onready var OptionsMenuPanel = %OptionsMenuPanel 
@onready var ManualControlHUD = %ManualControlHUD
@onready var TacticalMap = %TacticalDataDrawing
@onready var All = %All
@onready var Deploy = %Deploy
@onready var Cancel = %Cancel
@onready var PlayableAreaBounds = %PlayableAreaBounds
@onready var ComputerAdmiral = $Admiral
@onready var ImapDebug = $ImapDebug
@onready var ImapDebugGrid = $ImapDebug/ImapGridContainer

# Imap values and goodies
var debug_imap: bool = true
var battle_over: bool = false
var imap_debug_grid: Array
var combat_goal: int = globals.GOAL.SKIRMISH

# Enemy Deployment Variables (not actually friendly, I just enjoy reusing code)
var deployment_position: Vector2
var deployment_row: int = 0
var deployment_spacing: int = 500

signal units_deployed(units)

func _ready() -> void:
	ComputerAdmiral.SetGoal(combat_goal)
	process_mode = PROCESS_MODE_PAUSABLE
	TacticalMap.switch_maps.connect(_on_switch_maps)
	CombatMap.switch_maps.connect(_on_switch_maps)
	FleetDeploymentList.combat_goal = combat_goal
	imap_manager.InitializeArenaMaps()
	
	if debug_imap == true:
		var map: Object = imap_manager.GoalMap
		#print(map.get_signal_list())
		map.UpdateGridValue.connect(_on_grid_value_changed)
		map.UpdateRowValue.connect(_on_grid_row_changed)
		#vulnerability_map.update_grid_value.connect(_on_grid_value_changed)
		#vulnerability_map.update_row_value.connect(_on_grid_row_changed)
		var grid_row_size: int = map.Height
		var grid_column_size: int = map.Width
		#var grid_row_size: int = vulnerability_map.map_grid.size()
		#var grid_column_size: int = vulnerability_map.map_grid[0].size()
		ImapDebug.size = PlayableAreaBounds.shape.size
		ImapDebugGrid.columns = grid_column_size
		for i in range(grid_row_size):
			imap_debug_grid.append([])
			for j in range(grid_column_size):
				var cell_instance: Container = CELL_CONTAINER_SCENE.instantiate()
				cell_instance.custom_minimum_size = Vector2.ONE * imap_manager.DefaultCellSize
				cell_instance.get_child(0).text = str(map.GetCellValue(i, j))
				cell_instance.get_child(0).visible = false
				ImapDebugGrid.add_child(cell_instance)
				imap_debug_grid[i].append(cell_instance)
	
	FleetDeploymentList.setup_deployment_screen()
	settings.swizzle(FleetDeploymentPanel)
	settings.swizzle(%OptionsMenuPanel)
	settings.swizzle(%MainMenuButton)
	settings.swizzle(%ManualControlLoadingBar)
	settings.swizzle(All)
	settings.swizzle(Deploy)
	settings.swizzle(Cancel)
	#%BlackenBackground.size = PlayableAreaBounds.shape.size
	FleetDeploymentList.units_deployed.connect(TacticalMap.connect_unit_signals)
	self.units_deployed.connect(TacticalMap.connect_unit_signals)
	TacticalMap.display_map(true)
	
	FleetDeploymentList.deploy_ship.connect(self._add_player_ship)
	# Set combat boundaries using four static bodies and shapes. A>B order is important for one-way collision. I had to use Rects and do rotation magic due to global collisions.
	$CollisionBoundaryLeft.position = Vector2(0, PlayableAreaBounds.shape.size.y/2)
	$CollisionBoundaryLeft/CollisionBoundaryShape.shape.size = Vector2(PlayableAreaBounds.shape.size.y, 1) 
	
	$CollisionBoundaryTop.position = Vector2(PlayableAreaBounds.shape.size.x/2, 0)
	$CollisionBoundaryTop/CollisionBoundaryShape.shape.size = Vector2(PlayableAreaBounds.shape.size.x, 1 ) 
	
	$CollisionBoundaryRight.position = Vector2(PlayableAreaBounds.shape.size.x, PlayableAreaBounds.shape.size.y/2)
	$CollisionBoundaryRight/CollisionBoundaryShape.shape.size = Vector2(PlayableAreaBounds.shape.size.y, 1 ) 
	
	#$CollisionBoundaryRight.position =  Vector2(PlayableAreaBounds.shape.size.x,0)
	#$CollisionBoundaryRight/CollisionBoundaryShape.shape.a = Vector2(0, 0)
	#$CollisionBoundaryRight/CollisionBoundaryShape.shape.b = Vector2(0, PlayableAreaBounds.shape.size.y)
	
	$CollisionBoundaryBottom.position =  Vector2(0,0)
	$CollisionBoundaryBottom/CollisionBoundaryShape.shape.a = Vector2(0, PlayableAreaBounds.shape.size.y)
	$CollisionBoundaryBottom/CollisionBoundaryShape.shape.b = Vector2(PlayableAreaBounds.shape.size.x, PlayableAreaBounds.shape.size.y)
	
	# If we're loading directly into the combat arena scene without calling setup() do this.
	if get_tree().get_current_scene() == self:
		deploy_enemy_fleet()
	
func reset_deployment_position() -> void:
	# Start outside the map. Spawn ships starting at the top left quadrant of our 3 rowed, 7 columned rectangular ship formation.
	#					   ------- <- map boundary
	# starting position -> . . . . 
	# 					   . . . .
	# 					   . . . . <- ending position
	#deployment_position.x = PlayableAreaBounds.shape.size.x/2 - deployment_spacing * 3 # 3+1+3 = 7 columns, start leftmost
	#deployment_position.y = 0 - deployment_spacing * 2# Start at the (bottommost, we're deploying enemies now) row.
	
	# For debugging
	deployment_position.x = PlayableAreaBounds.shape.size.x/2 - deployment_spacing * 3 # 3+1+3 = 7 columns, start leftmost
	deployment_position.y = PlayableAreaBounds.shape.size.y/2 # Deploy at the center
	deployment_row = 0

# Called after ready to import parameters like tutorial mode or the enemy fleet.
func setup(enemy_fleet: Fleet = Fleet.new(), tutorial_enum: data.tutorial_type_enum = 0) -> void:
	var setup_enemy_fleet: Fleet = enemy_fleet
	if tutorial_enum == 0:
		%TutorialWalkthrough.visible = false
		$TacticalMapLayer/TacticalViewportContainer/TacticalViewport/TacticalDataDrawing/FogOfWar.visible = true
		%TutorialWalkthrough.process_mode = Node.PROCESS_MODE_DISABLED
		deploy_enemy_fleet(setup_enemy_fleet)
	else:
		%TutorialWalkthrough.visible = true
		$TacticalMapLayer/TacticalViewportContainer/TacticalViewport/TacticalDataDrawing/FogOfWar.visible = false
		%TutorialWalkthrough.process_mode = Node.PROCESS_MODE_ALWAYS
		if tutorial_enum == 1: # Basic movement and camera tutorial.
			%TutorialWalkthrough.setup(tutorial_enum) # skip deployment, we dont want enemy ships
		elif tutorial_enum == 2: # Tactics Tutorial.
			deploy_enemy_fleet(enemy_fleet)
			%TutorialWalkthrough.setup(tutorial_enum)
		elif tutorial_enum == 3: # Manual Control Tutorial
			setup_enemy_fleet.add_ship(ShipStats.new(data.ship_type_enum.CHALLENGER))
			deploy_enemy_fleet(setup_enemy_fleet)
			%TutorialWalkthrough.setup(tutorial_enum)
		get_tree().call_group("enemy", "set_combat_ai", false)
		get_tree().call_group("enemy", "tutorial_setup")

	
# Deploys (and potentially, if no fleet parameter is passed in, creates) the enemy fleet.
func deploy_enemy_fleet(enemy_fleet: Fleet = Fleet.new()) -> void:
	# Technically the enemy deployment position, row, and spacing. But I enjoy reusing code.
	reset_deployment_position()
	var positions: Array = []
	var ship_positions: Dictionary = {}
	var instantiated_units: Array[Ship]
	var enemy_fleet_size: int = 10
	ComputerAdmiral.SetNumDeployedUnits(enemy_fleet_size)
	# Create an enemy fleets ships if no fleet was passed in.
	if enemy_fleet.fleet_stats.ships.is_empty():
		for i in range (enemy_fleet_size):
			if i % 100 == 0:
				enemy_fleet.add_ship(ShipStats.new(data.ship_type_enum.TRIDENT))
			if i % 3 == 0:
				enemy_fleet.add_ship(ShipStats.new(data.ship_type_enum.ECLIPSE))
			else:
				enemy_fleet.add_ship(ShipStats.new(data.ship_type_enum.CHALLENGER))
	var iterator: int 
	for i in range (enemy_fleet.fleet_stats.ships.size()):
		var ship_instantiation: Ship = enemy_fleet.fleet_stats.ships[i].ship_hull.ship_packed_scene.instantiate()
		ship_instantiation.initialize(enemy_fleet.fleet_stats.ships[i])
		ship_instantiation.collision_layer = 4
		self.add_child(ship_instantiation)
		ship_instantiation.is_friendly = false
		instantiated_units.push_back(ship_instantiation)
		
		# Deployment Positioning
		if i % 7 == 0 and i != 0:
			deployment_row += 1
		# Iterator % 7. Iterator = 0-6 as remainder ( i == 6 == 7 ships). Then reset to 0 at iterator 7.
		ship_instantiation.global_position.x = deployment_position.x + i % 7 * deployment_spacing # Correct
		ship_instantiation.global_position.y = deployment_position.y - deployment_spacing * deployment_row # I want to start at the top in termso f Y
		positions.append(Vector2(ship_instantiation.global_position.x, ship_instantiation.global_position.y + deployment_spacing * 6 + deployment_spacing*deployment_row))
		ship_positions[ship_instantiation.global_position] = ship_instantiation
		var tmp_name: StringName = &"stringbean"
		ship_instantiation.add_to_group(&"enemy")
		ship_instantiation.posture = globals.Strategy.NEUTRAL
		ship_instantiation.group_add(tmp_name)
		ship_instantiation.ShipWrapper.Deployed.connect(ComputerAdmiral.OnUnitDeployed)
	
	var geo_median_ship: Vector2 = globals.geometric_median_of_objects(ship_positions.keys())
	var new_leader: Ship = globals.find_unit_nearest_to_median(geo_median_ship, ship_positions)
	var geo_median_formation: Vector2 = globals.geometric_median_of_objects(positions)
	geo_median_formation.x -= 1250
	geo_median_formation.y -= 1000
	new_leader.set_group_leader(true)
	new_leader.set_navigation_position(geo_median_formation)
	units_deployed.emit(instantiated_units) # Connects Unit Signals in TacticalMap
	imap_manager.RegisterAgents(instantiated_units, int(combat_goal))
	%TacticalDataDrawing.delayed_setup_call()

func _unhandled_input(event) -> void:
	if event is InputEventKey:
		if (event.keycode == KEY_G and event.pressed):
			toggle_fleet_deployment_panel()
		elif (event.keycode == KEY_ESCAPE and event.pressed):
			toggle_options_menu()
				

func _physics_process(delta):
	if battle_over == false and (get_tree().get_node_count_in_group(&"friendly") == 0 or get_tree().get_node_count_in_group(&"enemy") == 0):
		battle_over = true
	elif battle_over == true and (get_tree().get_node_count_in_group(&"friendly") > 0 and get_tree().get_node_count_in_group(&"enemy") > 0):
		battle_over = false
	
	if Engine.get_physics_frames() % 60 == 0 and battle_over == false:
		imap_manager.WeighForceDensity()

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
	if %TacticalMapLayer.visible == false:
		TacticalMap.display_map(true)
	elif %TacticalMapLayer.visible:
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

func _add_player_ship(ship) -> void:
	add_child(ship)

func _on_tree_exiting():
	imap_manager.OnCombatArenaExiting()
