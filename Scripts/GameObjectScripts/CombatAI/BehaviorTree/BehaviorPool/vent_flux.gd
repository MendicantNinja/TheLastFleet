extends LeafAction

var total_flux: float = 0.0
var safe_distance: float = 0.0
var offensive_threshold: float = 0.9
var def_neut_threshold: float = 0.7
var evasive_threshold: float = 0.5
var default_radius: int = 10

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if total_flux == 0.0:
		total_flux = agent.ship_stats.flux
	
	var flux_norm: float = (agent.soft_flux + agent.hard_flux) / total_flux
	if agent.vent_flux_flag == true and flux_norm == 0.0 and agent.working_map != null:
		agent.move_direction = Vector2.ZERO
		agent.working_map = null
	
	if flux_norm == 0.0:
		agent.vent_flux_flag = false
		return FAILURE
	
	if agent.combat_flag == true and agent.retreat_flag == false:
		if (agent.posture == globals.Strategy.NEUTRAL or agent.posture == globals.Strategy.DEFENSIVE) and flux_norm >= def_neut_threshold:
			agent.retreat_flag = true
		elif agent.posture == globals.Strategy.OFFENSIVE and flux_norm >= offensive_threshold:
			agent.retreat_flag = true
		elif agent.posture == globals.Strategy.EVASIVE and flux_norm >= evasive_threshold:
			agent.retreat_flag = true
	
	if agent.retreat_flag == true and agent.move_direction == Vector2.ZERO:
		agent.move_direction = retreat_direction(agent)
	elif agent.retreat_flag == true and Engine.get_physics_frames() % 80 == 0:
		agent.move_direction = retreat_direction(agent)
	
	var can_vent: bool = false
	if flux_norm > 0.0 and agent.combat_flag == false:
		can_vent = true
	
	if can_vent == true:
		agent.vent_flux_flag = true
		if agent.soft_flux > 0.0:
			agent.soft_flux -= agent.ship_stats.flux_dissipation + agent.ship_stats.bonus_flux_dissipation
		elif agent.hard_flux > 0.0:
			agent.hard_flux -= agent.ship_stats.flux_dissipation + agent.ship_stats.bonus_flux_dissipation
		agent.update_flux_indicators()
		if agent.targeted_by.is_empty():
			agent.retreat_flag = false
	
	if can_vent == false:
		agent.vent_flux_flag = false
	
	return FAILURE

func retreat_direction(agent: Ship) -> Vector2:
	var direction: Vector2 = Vector2.ZERO
	var agent_cell = Vector2i(agent.global_position.y / imap_manager.default_cell_size, agent.global_position.x / imap_manager.default_cell_size)
	var working_map: Imap = agent.working_map
	if agent.working_map == null:
		var height: int = default_radius * imap_manager.default_cell_size
		var width: int = default_radius * imap_manager.default_cell_size
		working_map = Imap.new(width, height, 0.0, 0.0, imap_manager.default_cell_size)
		working_map.map_type = imap_manager.MapType.VULNERABILITY_MAP
		imap_manager.vulnerability_map.add_into_map(working_map, agent_cell.y, agent_cell.x)
	elif Engine.get_physics_frames() % 60 == 0:
		imap_manager.vulnerability_map.add_into_map(working_map, agent_cell.y, agent_cell.x)
	
	agent.working_map = working_map
	var local_min_cells: Array = []
	var start_row: int = agent_cell.x - default_radius / 2
	if start_row < 0:
		start_row = 0
	var start_column: int = agent_cell.y - default_radius / 2
	if start_column < 0:
		start_column = 0
	for i in range(0, default_radius, 1):
		var local_row: Array = working_map.map_grid[i]
		var min_val: float = local_row.min()
		var local_col: int = local_row.find(min_val)
		var index: Vector2i = Vector2i(i, local_col)
		local_min_cells.append(index)
	
	var cell_distances: Dictionary = {}
	for cell in local_min_cells:
		var distance: float = agent_cell.distance_squared_to(cell)
		cell_distances[distance] = cell
	
	var geo_mean_cell: Vector2 = globals.geometric_median_of_objects(cell_distances.values())
	var min_dist: float = cell_distances.keys().min()
	var min_cell: Vector2i = cell_distances[min_dist]
	var min_cell_value: float = working_map.map_grid[min_cell.x][min_cell.y]
	
	var normalize_cells: Dictionary = {}
	for cell in local_min_cells:
		var normalize_cell_value: float = working_map.map_grid[cell.y][cell.x] / min_cell_value
		normalize_cells[normalize_cell_value] = cell
	
	var max_cell_value: float = normalize_cells.keys().max()
	var goal_cell: Vector2i = normalize_cells[max_cell_value]
	goal_cell.x += start_row
	goal_cell.y += start_column
	var goal_position: Vector2 = Vector2(goal_cell.y * imap_manager.default_cell_size, goal_cell.x * imap_manager.default_cell_size)
	direction = agent.global_position.direction_to(goal_position)
	return direction
