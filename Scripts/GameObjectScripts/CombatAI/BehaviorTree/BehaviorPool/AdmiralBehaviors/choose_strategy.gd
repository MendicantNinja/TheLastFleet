extends LeafAction

func tick(agent: GDAdmiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 240 != 0:
		return FAILURE
	
	var available_agents: Array = get_tree().get_nodes_in_group(&"agent")
	var admiral_strength: float = 0.0
	var player_strength: float = 0.0
	
	for unit in available_agents:
		if unit.approx_influence < 0.0:
			admiral_strength += unit.approx_influence
		else:
			player_strength += unit.approx_influence
	
	admiral_strength = admiral_strength
	var relative_strength = admiral_strength + player_strength
	if relative_strength < 0:
		agent.heuristic_strat = globals.Strategy.OFFENSIVE
	elif relative_strength > 0:
		agent.heuristic_strat = globals.Strategy.DEFENSIVE
	
	agent.admiral_strength = admiral_strength
	agent.player_strength = player_strength
	
	return FAILURE
