extends LeafAction

var time: float = 0.0
var delta: float = 0.0
var sensitivity: float = 0.8

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.vent_flux_flag == true or agent.fallback_flag == true or agent.retreat_flag == true or agent.target_unit == null:
		time = 0.0
		return FAILURE
	
	if agent.combat_flag == false:
		time = 0.0
		return FAILURE
	
	if agent.target_in_range == false and agent.target_unit != null:
		return FAILURE
	
	var speed_modifier: float = 0.0
	if (agent.soft_flux + agent.hard_flux) == 0.0:
		speed_modifier = agent.zero_flux_bonus
	
	var distance_to: float = agent.global_position.distance_to(agent.target_unit.global_position)
	var speed: float = agent.ship_stats.acceleration + agent.ship_stats.bonus_acceleration + speed_modifier
	var direction_to_path: Vector2 = agent.global_position.direction_to(agent.target_unit.global_position)
	var range_sensitivity: float = agent.average_weapon_range * sensitivity
	var velocity: Vector2 = Vector2.ZERO
	if distance_to > agent.average_weapon_range:
		var ratio: float = distance_to / agent.average_weapon_range
		speed *= ratio
		time = delta + agent.time_coefficient
		velocity = speed * time * direction_to_path
	elif distance_to < range_sensitivity:
		time = delta + agent.time_coefficient
		var ratio: float = (distance_to - range_sensitivity) / (agent.average_weapon_range - range_sensitivity)
		speed *= ratio
		direction_to_path = agent.transform.x
		velocity = speed * time * direction_to_path
	
	if velocity != Vector2.ZERO and agent.linear_velocity.length() < speed:
		time += delta + agent.time_coefficient
	else:
		time = 0.0
	
	if velocity != Vector2.ZERO:
		agent.heur_velocity = velocity
		agent.acceleration = velocity
	
	return FAILURE
