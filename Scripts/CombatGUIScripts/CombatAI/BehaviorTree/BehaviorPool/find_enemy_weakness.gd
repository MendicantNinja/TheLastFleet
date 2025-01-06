extends LeafAction

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 120 != 0:
		return FAILURE
	
	
	return FAILURE
