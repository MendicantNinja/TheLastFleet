extends LeafAction

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if agent.order_groups.is_empty():
		return SUCCESS
	
	var player_units: Array = get_tree().get_nodes_in_group(&"friendly")
	var player_unit_positions: Dictionary = {}
	for unit in player_units:
		player_unit_positions[unit.global_position] = unit
	
	var leader_positions: Dictionary = {}
	for group_name in agent.order_groups:
		var leader = agent.group_leaders[group_name]
		leader_positions[leader.global_position] = leader
	
	for position in leader_positions:
		var leader: Ship = leader_positions[position]
		var distance_to_leader: Dictionary = {}
		for unit_position in player_unit_positions:
			var distance_to: float = position.distance_squared_to(unit_position)
			var player_unit = player_unit_positions[unit_position]
			distance_to_leader[distance_to] = player_unit
		
		var min_distance: float = distance_to_leader.keys().min()
		var closest_unit = [distance_to_leader[min_distance]]
		leader.remove_blackboard_data(agent.target_key)
		leader.set_blackboard_data(leader.group_name + agent.group_targets_key_suffix, closest_unit)
		if leader.idle == true:
			get_tree().call_group(leader.group_name, "set_idle_flag", false)
	
	return SUCCESS
