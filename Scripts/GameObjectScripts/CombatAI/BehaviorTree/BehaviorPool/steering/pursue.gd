extends LeafAction

var target: Ship = null
var threat_radius: float = 0.0
var delta: float = 0.0
var time: float = 0.0
var decel_coe: float = 0.9
var sensitivity: float = 0.5
var prediction_window: float = 2.0

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.retreat_flag == true or agent.fallback_flag == true or agent.vent_flux_flag == true:
		time = 0.0
		return FAILURE
	elif agent.target_unit == null:
		time = 0.0
		return SUCCESS
	
	if (agent.target_unit.fallback_flag == true or agent.target_unit.retreat_flag == true) and agent.target_in_range == false:
		agent.target_unit.targeted_by.erase(agent)
		agent.set_target_for_weapons(null)
		agent.target_unit = null
		time = 0.0
		return SUCCESS
	
	if threat_radius == 0.0:
		delta = get_physics_process_delta_time()
		var radius: int = (agent.template_maps[imap_manager.MapType.THREAT_MAP].width - 1) / 2
		threat_radius = (radius * imap_manager.default_cell_size)
	
	if agent.target_unit != target:
		target = agent.target_unit
	
	agent.sleeping = false
	
	var direction_to_path: Vector2 = agent.global_position.direction_to(target.global_position)
	var distance_to: float = agent.global_position.distance_to(target.global_position)
	var speed: float = agent.ship_stats.acceleration + agent.ship_stats.bonus_acceleration
	var speed_modifier: float = 0.0
	if (agent.soft_flux + agent.hard_flux) == 0.0 and speed_modifier != agent.zero_flux_bonus:
		speed_modifier += agent.zero_flux_bonus
	speed += speed_modifier
	var desired_velocity: Vector2 = speed * direction_to_path * time
	
	if floor(target.linear_velocity.length()) > 0.0:
		var predict_agent_position: Vector2 = agent.global_position + desired_velocity
		var max_speed: float = target.ship_stats.acceleration + target.ship_stats.bonus_acceleration + target.zero_flux_bonus
		var predicted_direction: Vector2 = target.linear_velocity.normalized()
		var target_time: float = (delta + agent.time_coefficient) * prediction_window
		var predicted_velocity: Vector2 = max_speed * predicted_direction * target_time
		var predicted_position: Vector2 = predicted_velocity + target.global_position
		distance_to = predict_agent_position.distance_to(predicted_position)
		direction_to_path = predict_agent_position.direction_to(predicted_position)
	
	time += delta + agent.time_coefficient
	if time > 4.0:
		time = 0.0
	
	if distance_to > threat_radius:
		desired_velocity = direction_to_path * speed * time
	elif distance_to < threat_radius and distance_to > agent.average_weapon_range:
		agent.combat_flag = true
		var scale_speed: float = (distance_to - threat_radius) / (threat_radius - agent.average_weapon_range)
		if scale_speed < -0.7:
			scale_speed = 0.1
		speed *= scale_speed
		desired_velocity = direction_to_path * speed * time
	else:
		var scale_speed: float = (agent.average_weapon_range - distance_to) / agent.average_weapon_range
		desired_velocity = target.linear_velocity.normalized() * speed * scale_speed
	
	
	desired_velocity = desired_velocity.limit_length(agent.speed)
	agent.time = time
	agent.heur_velocity = desired_velocity
	agent.acceleration = desired_velocity
	return FAILURE
