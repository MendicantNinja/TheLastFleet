extends LeafAction

var delta: float = 0.0
func tick(agent: Ship, blackboard: Blackboard) -> int:
	if delta == 0.0:
		delta = get_physics_process_delta_time()
	
	var transform_look_at: Transform2D
	if agent.target_position != Vector2.ZERO:
		transform_look_at = agent.transform.looking_at(agent.target_position)
	
	if agent.target_unit != null:
		transform_look_at = agent.transform.looking_at(agent.target_unit.global_position)
	
	agent.transform = agent.transform.interpolate_with(transform_look_at, agent.ship_stats.turn_rate * delta)
	return SUCCESS
