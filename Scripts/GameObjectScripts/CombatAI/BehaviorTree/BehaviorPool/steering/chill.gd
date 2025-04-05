extends LeafAction

var delta: float = 0.0
var epsilon: float = 0.1

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.target_position != Vector2.ZERO or agent.target_unit != null or agent.targeted_units.is_empty() == false or agent.fallback_flag == true or agent.retreat_flag == true:
		agent.brake_flag = false
		agent.linear_damp = 0.0
		return SUCCESS
	
	if delta == 0.0:
		delta = get_physics_process_delta_time()
	
	var current_velocity: float = agent.linear_velocity.length()
	if floor(current_velocity) > 0.0:
		agent.linear_damp = 5.0
	elif current_velocity == 0.0:
		agent.linear_damp = 0.0
	
	if current_velocity == 0.0 and agent.brake_flag == true:
		agent.brake_flag = false
	
	return SUCCESS
