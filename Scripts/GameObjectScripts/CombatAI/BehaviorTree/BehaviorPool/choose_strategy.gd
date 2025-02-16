extends LeafAction

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 240 != 0:
		return FAILURE
	
	var available_agents: Array = get_tree().get_nodes_in_group(&"agent")
	var admiral_strength: float = 0.0
	var enemy_strength: float = 0.0
	
	for unit in available_agents:
		if unit.approx_influence < 0.0:
			admiral_strength += unit.approx_influence
		else:
			enemy_strength += unit.approx_influence
	
	admiral_strength = abs(admiral_strength)
	enemy_strength = enemy_strength
	
	if admiral_strength > enemy_strength:
		agent.heuristic_strat = globals.Strategy.OFFENSIVE
	elif admiral_strength < enemy_strength:
		agent.heuristic_strat = globals.Strategy.DEFENSIVE
	
	agent.admiral_strength = admiral_strength
	agent.enemy_strength = enemy_strength
	
	return FAILURE
