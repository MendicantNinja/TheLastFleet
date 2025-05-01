extends LeafAction

func tick(agent: GDAdmiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 480 != 0:
		return FAILURE
	
	var goal_map: GDImap = imap_manager.goal_map
	var goal_value: Dictionary = agent.goal_value
	
	#goal_map = add_influence_map_to_goal_map(goal_map)
	var norm_value: float = 0.0
	for cell in goal_value:
		var value: int = goal_value[cell]
		if value > 0:
			norm_value += 1
	
	if agent.isolated_cells.is_empty():
		norm_value = goal_value.size()
	
	goal_map.clear_map()
	var geo_mean_cell: Array = []
	if agent.available_groups.is_empty():
		return FAILURE 
	
	for group_name in agent.available_groups:
		var group: Array = get_tree().get_nodes_in_group(group_name)
		var positions: Array = []
		for unit in group:
			positions.append(unit.global_position)
		var geo_mean: Vector2 = globals.geometric_median_of_objects(positions)
		var cell: Vector2i = Vector2i(geo_mean.y / imap_manager.default_cell_size, geo_mean.x / imap_manager.default_cell_size)
		geo_mean_cell.append(cell)
	
	for goal_cell in goal_value:
		var geo_mean_dist: Dictionary = {}
		for cell in geo_mean_cell:
			var dist: float = cell.distance_squared_to(goal_cell)
			geo_mean_dist[dist] = cell
		var max_cell: Vector2i = geo_mean_dist[geo_mean_dist.keys().max()]
		var radius: int = max_cell.distance_to(goal_cell)
		goal_map = propagate_goal_values(goal_map, agent, radius, goal_cell, goal_value[goal_cell], norm_value)
	
	imap_manager.goal_map = goal_map
	return FAILURE

func propagate_goal_values(goal_map: GDImap, agent: GDAdmiral, radius: int, center: Vector2i, magnitude: float = 1.0, norm_val: float = 1.0) -> GDImap:
	var inf_map: GDImap = imap_manager.agent_maps[imap_manager.MapType.INFLUENCE_MAP]
	var start_col: int = max(0, center.y - radius)
	var end_col: int = min(center.y + radius, goal_map.width)
	var start_row: int = max(0, center.x - radius)
	var end_row: int = min(center.x + radius, goal_map.height)
	var n_mag: float = magnitude / norm_val
	
	for m in range(start_row, end_row, 1):
		for n in range(start_col, end_col, 1):
			var cell: Vector2i = Vector2i(m, n)
			var distance: float = center.distance_to(cell)
			var value: float = 0.0
			if goal_map.map_grid[m][n] != 0.0:
				value += goal_map.map_grid[m][n]
			value += magnitude - n_mag * (distance / radius)
			goal_map.map_grid[m][n] = value
			goal_map.update_grid_value.emit(m, n, value)
	
	return goal_map

func add_influence_map_to_goal_map(goal_map: GDImap) -> GDImap:
	var inf_map: GDImap = imap_manager.agent_maps[imap_manager.MapType.INFLUENCE_MAP]
	var height: int = inf_map.height
	var width: int = inf_map.width
	
	for m in range(height):
		var source_min: float = inf_map.map_grid[m].min()
		var source_max: float = inf_map.map_grid[m].max()
		if source_min <= 0.0 and source_max == 0.0:
			var fill_zero: Array = []
			fill_zero.resize(width)
			fill_zero.fill(0.0)
			goal_map.map_grid[m] = fill_zero
			#goal_map.update_row_value.emit(m, goal_map.map_grid[m])
			continue
		
		for n in range(width):
			var value: float = inf_map.map_grid[m][n]
			if value < 0.0:
				value = 0.0
			goal_map.map_grid[m][n] = -value
			if value != 0.0:
				goal_map.update_grid_value.emit(m, n, goal_map.map_grid[m][n])
	
	return goal_map
