extends LeafAction

var total_flux: float = 0.0

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if total_flux == 0.0:
		total_flux = agent.ship_stats.flux
	
	return FAILURE
