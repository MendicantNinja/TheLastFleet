extends LeafAction

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 45 != 0 and agent.registry_cell.x < 0 and agent.registry_cell.y < 0:
		return SUCCESS
	
	if agent.group_name.is_empty():
		return SUCCESS
		
	if agent.goal_flag == true and agent.combat_flag == false and agent.targeted_by.is_empty() == false:
		agent.goal_flag = false
		get_tree().call_group(agent.group_name, &"set_targets", [])
		get_tree().call_group(agent.group_name, &"set_goal_flag", false)
	
	if agent.goal_flag == true:
		return SUCCESS
	
	var group_strength: float = 0.0
	var group_positions: Array = []
	for unit in get_tree().get_nodes_in_group(agent.group_name):
		group_strength += unit.approx_influence
		group_positions.append(unit.global_position)
	var group_geo_median: Vector2 = globals.geometric_median_of_objects(group_positions)
	
	var player_registry_cells: Array = []
	var player_agents: Array = get_tree().get_nodes_in_group(&"friendly")
	for unit in player_agents:
		if unit.registry_cell.x < 0 or unit.registry_cell.y < 0:
			continue
		if unit == null:
			continue
		if unit.registry_cell not in player_registry_cells:
			player_registry_cells.append(unit.registry_cell)
	
	if player_registry_cells.is_empty():
		return SUCCESS
	
	var registry_neighborhood: Array = []
	var radius: int = 1
	for m in range(-radius, radius + 1, 1):
		for n in range(-radius, radius + 1, 1):
			var target_cell: Vector2i = Vector2i(agent.registry_cell.x + m, agent.registry_cell.y + n)
			if target_cell.x < 0:
				target_cell.x = 0
			if target_cell.y < 0:
				target_cell.y = 0
			if target_cell not in registry_neighborhood:
				registry_neighborhood.append(target_cell)
	
	var cell_in_neighborhood: Array = []
	if agent.combat_goal == globals.GOAL.SKIRMISH:
		for cell in player_registry_cells:
			if cell in registry_neighborhood and cell not in cell_in_neighborhood:
				cell_in_neighborhood.append(cell)
		
		if not cell_in_neighborhood.is_empty():
			agent.goal_flag = true
		else:
			agent.goal_flag = false
	
	if agent.combat_goal == globals.GOAL.SKIRMISH and agent.goal_flag == true:
		var target_cells: Dictionary = {}
		var target_strength: Dictionary = {}
		var target_geo_median: Dictionary = {}
		for cell in imap_manager.registry_map:
			var agents_in_cell: Array = imap_manager.registry_map[cell]
			var player_units: Array = []
			var relative_strength: float = 0.0
			var unit_positions: Array = []
			for unit in agents_in_cell:
				if unit == null:
					continue
				if unit.is_friendly == true:
					player_units.append(unit)
					relative_strength += unit.approx_influence
					unit_positions.append(unit.global_position)
			if not player_units.is_empty():
				var geo_median: Vector2 = globals.geometric_median_of_objects(unit_positions)
				target_cells[cell] = player_units
				target_strength[cell] = relative_strength
				target_geo_median[cell] = geo_median
		
		if target_cells.size() == 1:
			var target_units: Array = target_cells[target_cells.keys()[0]]
			get_tree().call_group(agent.group_name, &"set_targets", target_units)
			get_tree().call_group(agent.group_name, &"set_goal_flag", true)
			return SUCCESS
		
		var dist_to_cell: Array = []
		for cell in target_geo_median:
			var player_geo_median: Vector2 = target_geo_median[cell]
			var dist_to: float = group_geo_median.distance_squared_to(player_geo_median)
			dist_to_cell.append(dist_to)
		
		var weigh_strength: Dictionary = {}
		var min_dist: float = dist_to_cell.min()
		for cell in target_strength:
			var target_median: Vector2 = target_geo_median[cell]
			var relative_strength: float = target_strength[cell]
			var dist_to: float = group_geo_median.distance_squared_to(target_median)
			var reweighed_strength: float = group_strength + relative_strength * (min_dist / dist_to)
			weigh_strength[reweighed_strength] = cell
		
		var min_strength: float = weigh_strength.keys().min()
		var max_strength: float = weigh_strength.keys().max()
		var target_units: Array = []
		var target_cell_key: Vector2i = weigh_strength[min_strength]
		target_units = target_cells[target_cell_key]
		get_tree().call_group(agent.group_name, &"set_targets", target_units)
		
		
		
	return SUCCESS
