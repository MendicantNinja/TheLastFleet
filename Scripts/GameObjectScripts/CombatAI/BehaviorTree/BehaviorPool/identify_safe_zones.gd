extends LeafAction

var safe_zones: Array = []

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 180 and agent.fallback_flag == false:
		return SUCCESS
	
	var friendly_groups: Array = []
	
	
	return SUCCESS
