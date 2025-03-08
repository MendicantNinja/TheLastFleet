extends LeafAction

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.shield_toggle == true and agent.combat_flag == false:
		agent.set_shields(false)
	
	if agent.combat_flag == false:
		return FAILURE
	
	if agent.combat_flag == true and agent.shield_toggle == false:
		agent.set_shields(true)
	
	return FAILURE
