extends LeafAction

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.combat_goal != globals.GOAL.SKIRMISH or agent.group_name.is_empty() or (agent.registry_cell.x < 0 and agent.registry_cell.y < 0):
		return SUCCESS
	
	if Engine.get_physics_frames() % 65 != 0:
		return FAILURE
	
	if agent.targeted_units.is_empty() == false and agent.target_unit != null:
		return SUCCESS
	
	var group_strength: float = 0.0
	var group_positions: Array = []
	for unit in get_tree().get_nodes_in_group(agent.group_name):
		group_strength += unit.approx_influence
		group_positions.append(unit.global_position)
	var group_geo_median: Vector2 = globals.geometric_median_of_objects(group_positions)
	
	var player_registry_cells: Array = []
	var player_agents: Array = get_tree().get_nodes_in_group(&"friendly")
	var registry_cluster: Dictionary = {}
	for unit in player_agents:
		if unit.registry_cell.x < 0 or unit.registry_cell.y < 0:
			continue
		if unit == null:
			continue
		if unit.registry_cell not in player_registry_cells:
			player_registry_cells.append(unit.registry_cell)
		if unit.registry_cluster not in registry_cluster:
			registry_cluster[unit.registry_cluster] = []
		registry_cluster[unit.registry_cluster].append(unit)
	
	if player_registry_cells.is_empty():
		return SUCCESS
	
	var registry_neighborhood = agent.registry_neighborhood
	for cell in player_registry_cells:
		if cell in registry_neighborhood:
			agent.goal_flag = true
			break
	
	if agent.goal_flag == false:
		return SUCCESS
	
	var target_strength: Dictionary = {}
	var target_geo_median: Dictionary = {}
	for cluster in registry_cluster:
		var agents_in_cluster: Array = registry_cluster[cluster]
		var relative_strength: float = 0.0
		var unit_positions: Array = []
		for unit in agents_in_cluster:
			if unit == null:
				continue
			relative_strength += unit.approx_influence
			unit_positions.append(unit.global_position)
		var geo_median: Vector2 = globals.geometric_median_of_objects(unit_positions)
		target_strength[cluster] = relative_strength
		target_geo_median[cluster] = geo_median
	
	if registry_cluster.size() == 1:
		var target_units: Array = registry_cluster[registry_cluster.keys()[0]]
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
		var weight: float = dist_to / min_dist
		var reweighed_strength: float = group_strength + relative_strength * weight
		weigh_strength[reweighed_strength] = cell
	
	var min_strength: float = weigh_strength.keys().min()
	var max_strength: float = weigh_strength.keys().max()
	var target_units: Array = []
	var cluster_key: Array = weigh_strength[min_strength]
	target_units = registry_cluster[cluster_key]
	get_tree().call_group(agent.group_name, &"set_targets", target_units)
	get_tree().call_group(agent.group_name, &"set_goal_flag", true)
	return SUCCESS
