extends LeafAction

var time: float = 0.0
var delta: float = 0.0

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.retreat_flag == false and agent.fallback_flag == false:
		time = 0.0
		return FAILURE
	
	if delta == 0.0:
		delta = get_physics_process_delta_time()
	
	var move_direction: Vector2 = agent.move_direction
	var speed_modifier: float = 0.0
	if (agent.soft_flux + agent.hard_flux) == 0.0:
		speed_modifier = agent.zero_flux_bonus
	var accel_speed: float = agent.ship_stats.acceleration + agent.ship_stats.bonus_acceleration + speed_modifier
	
	if agent.linear_velocity.length() < accel_speed:
		time += delta + agent.time_coefficient
	if time > 4.0:
		time = 0.0
	
	var velocity = move_direction * accel_speed * time
	velocity = velocity.limit_length(agent.speed)
	agent.heur_velocity = velocity
	agent.acceleration = velocity
	agent.time = time
	
	return FAILURE
