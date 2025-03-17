extends LeafAction

var overload_thresh: float = 0.95

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.vent_flux_flag == true or agent.flux_overload == true:
		return FAILURE
	
	if agent.shield_toggle == true and agent.combat_flag == false:
		agent.set_shields(false)
		return FAILURE
	
	if agent.vent_flux_flag == true and agent.fallback_flag == false:
		agent.set_shields(false)
		return FAILURE
	
	if agent.combat_flag == false:
		return FAILURE
	
	var flux_norm: float = (agent.soft_flux + agent.hard_flux) / agent.total_flux
	if flux_norm >= overload_thresh:
		agent.set_shields(false)
		return FAILURE
	
	if agent.combat_flag == true and agent.shield_toggle == false:
		agent.set_shields(true)
	
	return FAILURE
