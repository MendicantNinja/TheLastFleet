extends LeafAction

var visited: Array = []

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 240 != 0:
		return FAILURE
	
	if agent.awaiting_orders.is_empty():
		return SUCCESS
	
	var isolated_targets: Array = agent.isolated_targets
	var vulnerable_targets: Dictionary = agent.vulnerable_targets
	
	return FAILURE
