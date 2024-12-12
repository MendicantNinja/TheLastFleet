extends LeafCondition

func tick(agent: Ship, blackboard: Blackboard) -> int:
	var total_hull_integrity: float = agent.ship_stats.hull_integrity
	var hull_integrity_assess: float = agent.hull_integrity / total_hull_integrity
	if hull_integrity_assess <= 0.3:
		return SUCCESS
	return FAILURE
