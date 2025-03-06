extends LeafAction

var debug: bool = false

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if debug == true:
		return FAILURE
	
	if agent.target_position == Vector2.ZERO or agent.group_name.is_empty() == true:
		return FAILURE
	
	var speeds: Array = []
	for unit in get_tree().get_nodes_in_group(agent.group_name):
		speeds.append(unit.linear_velocity.length())
	
	var velocity: Vector2 = agent.heur_velocity
	var min_velocity: float = speeds.min()
	if min_velocity == 0 or min_velocity > agent.speed:
		return FAILURE
	
	if velocity.length() > min_velocity:
		velocity = velocity.limit_length(min_velocity)
	
	agent.heur_velocity = velocity
	agent.acceleration = velocity
	return FAILURE
