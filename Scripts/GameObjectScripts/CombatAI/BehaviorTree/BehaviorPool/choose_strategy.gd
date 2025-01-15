extends LeafAction

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 240 != 0:
		return FAILURE
	
	var available_agents: Array = get_tree().get_nodes_in_group(&"agent")
	var enemy_unit_size: int = get_tree().get_node_count_in_group(&"friendly")
	var admiral_unit_size: int = get_tree().get_node_count_in_group(&"enemy")
	var admiral_strength: float = 0.0
	var enemy_strength: float = 0.0
	
	for unit in available_agents:
		if unit.approx_influence < 0.0:
			admiral_strength += unit.approx_influence
		else:
			enemy_strength += unit.approx_influence
	
	admiral_strength = abs(admiral_strength) / admiral_unit_size
	enemy_strength = enemy_strength / enemy_unit_size
	
	if admiral_strength > enemy_strength:
		agent.heuristic_strat = globals.Strategy.OFFENSIVE
	elif admiral_strength < enemy_strength:
		agent.heuristic_strat = globals.Strategy.DEFENSIVE
	
	return FAILURE
