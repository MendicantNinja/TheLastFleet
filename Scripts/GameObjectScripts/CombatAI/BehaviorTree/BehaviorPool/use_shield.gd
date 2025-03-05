extends LeafAction

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.shield_toggle == true and agent.combat_flag == false:
		agent.set_shields(false)
	
	if agent.combat_flag == false:
		return FAILURE
	
	if agent.posture == globals.Strategy.DEFENSIVE or agent.posture == globals.Straegy.NEUTRAL:
		pass
	
	return FAILURE
