extends LeafAction

func tick(agent: Ship, blackboard: Blackboard) -> int:
	agent.set_shields(true)
	if agent.shield_toggle == true:
		return SUCCESS
	return RUNNING
