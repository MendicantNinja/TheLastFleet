extends LeafAction

var time: float = 0.0
var delta: float = 0.0

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.target_unit == null or agent.target_in_range == false:
		return FAILURE
	
	var speed_modifier: float = 0.0
	if (agent.soft_flux + agent.hard_flux) == 0.0:
		speed_modifier = agent.zero_flux_bonus
	
	var distance_to: float = agent.global_position.distance_to(agent.target_unit.global_position)
	if distance_to > agent.average_weapon_range or time > 4.0:
		time = 0.0
	
	if distance_to < agent.average_weapon_range:
		var ratio: float = 1 - distance_to / agent.average_weapon_range
		var speed: float = agent.ship_stats.acceleration + agent.ship_stats.bonus_acceleration + speed_modifier
		speed *= ratio
		time += delta + agent.time_coefficient
		var direction_to_path: Vector2 = -agent.global_position.direction_to(agent.target_unit.global_position)
		var velocity: Vector2 = speed * time * direction_to_path
		agent.time = time
		agent.heur_velocity = velocity
		agent.acceleration = velocity
	
	return FAILURE
