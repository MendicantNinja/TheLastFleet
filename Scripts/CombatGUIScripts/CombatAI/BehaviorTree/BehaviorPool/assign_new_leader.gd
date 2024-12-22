extends LeafAction

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if agent.assign_new_leader_group.is_empty():
		return FAILURE
	
	var unit_positions: Dictionary = {}
	var group: Array = agent.available_groups[agent.assign_new_leader_group]
	var new_leader = null
	if group.size() == 1:
		new_leader = group[0]
	elif group.size() > 1:
		for unit in group:
			unit_positions[unit.global_position] = unit
		var median: Vector2 = globals.geometric_median_of_objects(unit_positions)
		new_leader = globals.find_unit_nearest_to_median(median, unit_positions)
		new_leader.destroyed.disconnect(agent._on_unit_destroyed)
		new_leader.destroyed.connect(agent._on_leader_destroyed.bind(new_leader, new_leader.group_name)) 
	
	agent.assign_new_leader_group = &""
	new_leader.set_group_leader(true)
	return SUCCESS
