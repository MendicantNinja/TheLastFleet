extends LeafAction

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.retreat_flag == true or (agent.fallback_flag == true and agent.vent_flux_flag == true):
		return FAILURE
	
	return FAILURE
