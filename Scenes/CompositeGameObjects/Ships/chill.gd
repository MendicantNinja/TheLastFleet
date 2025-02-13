extends LeafAction

var time: float = 0.0
var delta: float = 0.0
func tick(agent: Ship, blackboard: Blackboard) -> int:
	time = 0.0
	if agent.combat_flag == true or agent.vent_flux_flag == true or agent.retreat_flag == true:
		return FAILURE
	
	if agent.target_position != Vector2.ZERO or agent.target_unit != null:
		return FAILURE
	
	if delta == 0.0:
		delta = get_physics_process_delta_time()
	
	var current_velocity: float = agent.linear_velocity.length()
	
	if floor(current_velocity) == 0.0:
		return SUCCESS
	
	if agent.time != 0.0:
		time = agent.time
	
	if floor(current_velocity) != 0.0 and agent.time > 0.0:
		time += delta + agent.time_coefficient
	
	var velocity = -agent.linear_velocity.normalized() * (agent.ship_stats.deceleration + agent.ship_stats.bonus_deceleration) * time
	if floor(velocity.length()) == 0.0:
		velocity = 0.0
		time = 0.0
	
	agent.time = time
	agent.heur_velocity = velocity
	agent.acceleration = velocity
	return FAILURE
