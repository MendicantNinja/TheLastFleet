extends LeafAction

func tick(agent: Ship, blackboard: Blackboard) -> int:
	var total_hull_integrity: float = agent.ship_stats.hull_integrity
	var hull_integrity_assess: float = agent.hull_integrity / total_hull_integrity
	var total_flux_capacity: float = agent.total_flux
	var current_flux_capacity: float = agent.hard_flux + agent.soft_flux
	var flux_assess: float = current_flux_capacity / total_flux_capacity
	if hull_integrity_assess <= 0.3 and flux_assess < 0.9 and agent.shield_toggle == false:
		agent.set_shields(true)
	elif flux_assess >= 0.9 and agent.shield_toggle == true:
		agent.set_shields(false)
	
	if agent.shield_toggle == true:
		return SUCCESS
	
	return FAILURE
