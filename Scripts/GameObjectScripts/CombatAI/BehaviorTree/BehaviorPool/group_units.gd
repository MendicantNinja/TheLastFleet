extends LeafAction

var tmp_name: StringName = &"temporary enemy group"

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 240 != 0:
		return FAILURE
	
	var available_units: Array = get_tree().get_nodes_in_group(&"enemy")
	var lone_units: Array = []
	var units_ranked: Dictionary = {}
	for unit in available_units:
		if unit.group_name.is_empty():
			lone_units.append(unit)
		if not units_ranked.has(unit.approx_influence):
			units_ranked[unit.approx_influence] = []
		if unit not in units_ranked[unit.approx_influence]:
			units_ranked[unit.approx_influence].append(unit)
	
	if lone_units.is_empty():
		return FAILURE
	
	var max_rank: float = units_ranked.keys().max()
	var min_rank: float = units_ranked.keys().min()
	
	if max_rank == min_rank and not lone_units.is_empty() and agent.heuristic_strat == globals.Strategy.DEFENSIVE:
		var unit_positions: Dictionary = {}
		available_units = units_ranked[max_rank]
		for unit in available_units:
			if unit in lone_units:
				unit_positions[unit.global_position] = unit
		var geo_median: Vector2 = globals.geometric_median_of_objects(unit_positions.keys())
		var group_leader: Ship = globals.find_unit_nearest_to_median(geo_median, unit_positions)
		var group_name: StringName = agent.group_key_prefix + str(agent.iterator)
		agent.iterator += 1
		get_tree().call_group(&"enemy", "group_add", group_name)
		group_leader.set_group_leader(true)
		agent.awaiting_orders.append(group_name)
		agent.queue_orders[agent.posture_key] = agent.heuristic_strat
	
	return SUCCESS
