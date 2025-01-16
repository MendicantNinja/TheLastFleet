extends LeafAction

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.ShipNavigationAgent.is_navigation_finished():
		agent.rotate_angle = 0.0
		agent.move_direction = Vector2.ZERO
		return SUCCESS
	
	var velocity = Vector2.ZERO
	
	if not agent.ShipNavigationAgent.is_navigation_finished():
		
		if agent.manual_control == true:
			agent.ShipNavigationAgent.set_target_position(agent.global_position)
			return SUCCESS
		
		var next_path_position = agent.ShipNavigationAgent.get_next_path_position()
		var direction_to_path: Vector2 = agent.global_position.direction_to(next_path_position)
		velocity = direction_to_path * agent.movement_delta
		var ease_velocity: Vector2 = Vector2.ZERO
		var normalize_velocity_x: float = agent.linear_velocity.x / velocity.x
		var normalize_velocity_y: float = agent.linear_velocity.y / velocity.y
		if velocity.x == 0.0:
			normalize_velocity_x = 0.0
		if velocity.y == 0.0:
			normalize_velocity_y = 0.0
		ease_velocity.x = (velocity.x + agent.linear_velocity.x) * ease(normalize_velocity_x, agent.ship_stats.acceleration)
		ease_velocity.y = (velocity.y + agent.linear_velocity.y) * ease(normalize_velocity_y, agent.ship_stats.acceleration)
		velocity += ease_velocity
		var transform_look_at: Transform2D = agent.transform.looking_at(next_path_position)
		agent.transform = agent.transform.interpolate_with(transform_look_at, agent.rotational_delta)
	
	agent.acceleration = velocity - agent.linear_velocity
	if (agent.acceleration.abs().floor() != Vector2.ZERO or agent.manual_control) and agent.sleeping:
		agent.sleeping = false
	
	return FAILURE
