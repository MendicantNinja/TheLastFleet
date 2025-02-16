extends LeafAction

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 240 != 0:
		return FAILURE
	
	var available_units: Array = get_tree().get_nodes_in_group(&"enemy")
	var lone_units: Array = []
	var unit_ranks: Dictionary = {}
	for unit in available_units:
		var floor_inf: float = floor(unit.approx_influence)
		if unit.group_name.is_empty():
			lone_units.append(unit)
		if not unit_ranks.has(floor_inf):
			unit_ranks[floor_inf] = []
		if unit not in unit_ranks[floor_inf]:
			unit_ranks[floor_inf].append(unit)
	
	if lone_units.is_empty():
		return FAILURE
	
	var enemy_units: Array = get_tree().get_nodes_in_group(&"friendly")
	var enemy_ranks: Dictionary = {}
	var average_enemy_strength: float = 0.0
	for unit in enemy_units:
		var floor_inf: float = ceil(unit.approx_influence)
		if not enemy_ranks.has(floor_inf):
			enemy_ranks[floor_inf] = []
		if unit not in enemy_ranks[floor_inf]:
			enemy_ranks[floor_inf].append(unit)
		average_enemy_strength += floor_inf
	
	average_enemy_strength /= enemy_units.size()
	average_enemy_strength = floor(average_enemy_strength)
	
	var weighted_ranks: Dictionary = {}
	var rank_sizes: Array = []
	for rank in unit_ranks.keys():
		var units = unit_ranks[rank]
		var weigh_rank: float = -floor(rank / average_enemy_strength)
		weighted_ranks[weigh_rank] = units
		rank_sizes.append(units.size())
	
	var unit_positions: Dictionary = {}
	for unit in available_units:
		if unit in lone_units:
			unit_positions[unit.global_position] = unit
	var geo_median: Vector2 = globals.geometric_median_of_objects(unit_positions.keys())
	
	if agent.heuristic_strat == globals.Strategy.DEFENSIVE:
		var group_leader: Ship = globals.find_unit_nearest_to_median(geo_median, unit_positions)
		var group_name: StringName = agent.group_key_prefix + str(agent.iterator)
		agent.iterator += 1
		get_tree().call_group(&"enemy", "group_add", group_name)
		group_leader.set_group_leader(true)
		agent.awaiting_orders.append(group_name)
		agent.queue_orders[agent.posture_key] = agent.heuristic_strat
	elif agent.heuristic_strat == globals.Strategy.OFFENSIVE:
		var ratio: int = available_units.size() / enemy_units.size()
		var remainder: int = available_units.size() % enemy_units.size()
		for i in range(0, ratio, 1):
			pass
		
		pass
	
	
	return SUCCESS
