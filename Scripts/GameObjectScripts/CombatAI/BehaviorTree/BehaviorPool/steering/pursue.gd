extends LeafAction

var target: Ship = null
var threat_radius: float = 0.0
var delta: float = 0.0
var time: float = 0.0
var decel_coe: float = 0.9

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.target_unit != null and (agent.target_unit.retreat_flag == true or agent.fallback_flag == true):
		agent.target_unit.targeted_by.erase(agent)
		agent.target_unit = null
		return FAILURE
	elif agent.retreat_flag == true or agent.vent_flux_flag == true:
		return FAILURE
	
	if agent.target_unit == null:
		return SUCCESS
	
	if threat_radius == 0.0:
		delta = get_physics_process_delta_time()
		var radius: int = (agent.template_maps[imap_manager.MapType.THREAT_MAP].width - 1) / 2
		threat_radius = (radius * imap_manager.default_cell_size)
	
	if agent.target_unit != target:
		target = agent.target_unit
	
	if agent.linear_damp > 0.0 and agent.brake_flag == true:
		agent.brake_flag = false
		agent.linear_damp = 0.0
	
	agent.sleeping = false
	var direction_to_path: Vector2 = agent.global_position.direction_to(target.global_position)
	var distance_to: float = agent.global_position.distance_to(target.global_position)
	var speed: float = agent.ship_stats.acceleration + agent.ship_stats.bonus_acceleration
	var speed_modifier: float = 0.0
	if (agent.soft_flux + agent.hard_flux) == 0.0 and speed_modifier != agent.zero_flux_bonus:
		speed_modifier += agent.zero_flux_bonus
	
	if floor(target.linear_velocity.length()) > 0.0:
		var max_speed: float = target.ship_stats.acceleration + target.ship_stats.bonus_acceleration + target.zero_flux_bonus
		var predicted_direction: Vector2 = target.heur_velocity.normalized()
		var target_time: float = (delta + agent.time_coefficient) * 3.0
		var predicted_velocity: Vector2 = max_speed * predicted_direction * target_time
		var predicted_position: Vector2 = predicted_velocity + target.global_position
		distance_to = agent.global_position.distance_to(predicted_position)
		direction_to_path = agent.global_position.direction_to(predicted_position)
	
	if agent.target_in_range == false:
		time += delta + agent.time_coefficient
	if time > 4.0:
		time = 0.0
	
	speed += speed_modifier
	var brake_distance: float = (agent.speed ** 2) / (2.0 * agent.ship_stats.deceleration)
	if distance_to <= threat_radius and distance_to > agent.average_weapon_range:
		speed = speed * (distance_to / agent.average_weapon_range)
	elif distance_to <= threat_radius and agent.target_in_range == false:
		speed = speed * (threat_radius / distance_to)
		direction_to_path = -agent.linear_velocity.normalized()
	
	var velocity: Vector2 = Vector2.ZERO
	velocity = direction_to_path * speed * time
	velocity = velocity.limit_length(agent.speed)
	agent.time = time
	agent.heur_velocity = velocity
	agent.acceleration = velocity
	return FAILURE
