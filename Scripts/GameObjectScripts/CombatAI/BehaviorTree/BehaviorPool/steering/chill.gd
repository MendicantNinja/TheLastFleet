extends LeafAction

var delta: float = 0.0
var time: float = 0.0
var epsilon: float = 0.1

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.combat_flag == true or agent.retreat_flag == true or agent.target_unit != null:
		return FAILURE
	
	if agent.vent_flux_flag == true and agent.retreat_flag == true:
		return FAILURE
	
	if agent.target_unit == null and agent.target_position != Vector2.ZERO:
		return FAILURE
	
	if delta == 0.0:
		delta = get_physics_process_delta_time()
	
	var current_velocity: float = agent.linear_velocity.length()
	agent.combat_flag = false
	agent.retreat_flag = false
	
	if agent.brake_flag == true and current_velocity > epsilon:
		return FAILURE
	elif agent.brake_flag == true and current_velocity <= epsilon:
		time = 0.0
		agent.time = time
		return SUCCESS
	
	if agent.time != 0.0 and time > agent.time:
		time = agent.time
	else:
		time += delta + agent.time_coefficient
	
	var velocity = -agent.linear_velocity.normalized() * (agent.ship_stats.deceleration + agent.ship_stats.bonus_deceleration) * time
	
	agent.heur_velocity = velocity
	agent.acceleration = velocity
	return FAILURE
