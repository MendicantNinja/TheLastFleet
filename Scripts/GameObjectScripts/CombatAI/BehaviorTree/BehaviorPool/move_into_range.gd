extends LeafAction

var target_key: StringName = &"target"

func tick(agent: Ship, blackboard: Blackboard) -> int:
	var target = blackboard.ret_data(target_key)
	if target == null:
		return RUNNING
	
	var in_range: bool = agent.target_in_range
	if in_range:
		return SUCCESS
	
	var direction_to_target: Vector2 = agent.position.direction_to(target.position)
	var transform_look_at: Transform2D = agent.transform.looking_at(target.position)
	var new_velocity: Vector2 = direction_to_target * agent.movement_delta
	new_velocity += agent.ease_velocity(new_velocity)
	agent.transform = agent.transform.interpolate_with(transform_look_at, agent.rotational_delta)
	agent.acceleration = new_velocity - agent.linear_velocity
	
	return FAILURE
