extends LeafAction

var time: float = 0.0
var delta: float = 0.0

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.retreat_flag == false and agent.vent_flux_flag == false:
		time = 0.0
		return FAILURE
	
	if delta == 0.0:
		delta = get_physics_process_delta_time()
	
	var move_direction: Vector2 = agent.move_direction
	var speed_modifier: float = 0.0
	if (agent.soft_flux + agent.hard_flux) == 0.0:
		speed_modifier = agent.zero_flux_bonus
	var accel_speed: float = agent.ship_stats.acceleration + speed_modifier
	
	time = agent.time
	if agent.time == 0.0:
		time += delta + agent.time_coefficient
	elif agent.linear_velocity.length() < accel_speed:
		time += delta + agent.time_coefficient
	
	var velocity = move_direction * accel_speed
	velocity = velocity.limit_length(accel_speed)
	if agent.combat_flag == false and agent.vent_flux_flag == true:
		velocity = -agent.linear_velocity.normalized() * agent.ship_stats.deceleration * time
		if floor(agent.linear_velocity.length()) == 0.0:
			agent.retreat_flag = false
	
	agent.heur_velocity = velocity
	agent.acceleration = velocity
	agent.time = time
	return FAILURE
