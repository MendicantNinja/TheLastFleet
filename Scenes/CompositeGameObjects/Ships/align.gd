extends LeafAction

var target_position: Vector2 = Vector2.ZERO
var delta: float = 0.0

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.linear_velocity.length() > 0.0 and target_position != agent.target_position:
		var brake_distance: float = (agent.linear_velocity.length() ** 2) / (2.0 * agent.ship_stats.deceleration)
		var velocity = agent.heur_velocity
		if agent.global_position.distance_to(agent.target_position) <= brake_distance:
			velocity -= agent.linear_velocity.normalized() * agent.ship_stats.deceleration
			agent.heur_velocity = velocity
		agent.acceleration = agent.heur_velocity
		print(agent.linear_velocity)
		return RUNNING
	
	if agent.target_position != Vector2.ZERO:
		target_position = agent.target_position
	elif agent.target_ship != null:
		target_position = agent.target_ship.global_position
	else:
		return FAILURE
	
	if delta == 0.0:
		delta = get_physics_process_delta_time()
	
	var direction_to_path: Vector2 = agent.global_position.direction_to(target_position)
	var angle: float = direction_to_path.angle()
	

	
	var transform_look_at: Transform2D = agent.transform.looking_at(target_position)
	agent.transform = agent.transform.interpolate_with(transform_look_at, delta)
	
	if snappedf(agent.rotation, 0.1) == snappedf(angle, 0.1):
		return FAILURE
	
	return RUNNING
