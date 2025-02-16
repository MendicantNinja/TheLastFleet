extends LeafAction

var target_group_const: StringName = &" targets"

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.target_ship != null:
		return SUCCESS
	if agent.group_name.is_empty() == false and agent.group_leader == false:
		return SUCCESS
	
	var agent_group_name: StringName = agent.group_name
	var group: Array = get_tree().get_nodes_in_group(agent_group_name)
	var target_group_key = agent_group_name + target_group_const
	var available_targets: Array = []
	available_targets = blackboard.ret_data(target_group_key)
	
	var unit_pos: Array = []
	for target in available_targets:
		if target != null:
			unit_pos.append(target.global_position)
	for unit in group:
		if unit != null:
			unit_pos.append(unit.global_position)
	var unit_median: Vector2 = globals.geometric_median_of_objects(unit_pos)
	
	var target_dist: Dictionary = {}
	for target in available_targets:
		if target != null:
			var dist_to: float = target.distance_squared_to(unit_median)
			target_dist[dist_to] = target
	
	var group_dist: Dictionary = {}
	for unit in group:
		if unit != null:
			var dist_to: float = unit.distance_squared_to(unit_median)
			group_dist[dist_to] = unit
	
	var sort_group_dist: Array = group_dist.keys()
	sort_group_dist.sort()
	var sort_target_dist: Array = target_dist.keys()
	sort_target_dist.sort()
	
	var visited: Array = []
	for dist in sort_target_dist:
		var target: Ship = target_dist[dist]
		if target == null:
			continue
		for n_dist in sort_group_dist:
			pass
	return SUCCESS
