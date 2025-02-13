extends LeafAction

var target: Ship = null
var threat_radius: float = 0.0
var delta: float = 0.0
var time: float = 0.0

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.retreat_flag == true:
		return FAILURE
	
	if agent.target_unit == null:
		return FAILURE
	
	if threat_radius == 0.0:
		delta = get_physics_process_delta_time()
		var radius: int = agent.template_maps[imap_manager.MapType.THREAT_MAP].width
		threat_radius = (radius * imap_manager.default_cell_size) * 0.5
	
	if agent.target_unit != target:
		target = agent.target_unit
	
	if agent.linear_damp > 0.0 and agent.brake_flag == true:
		agent.brake_flag = false
		agent.linear_damp = 0.0
	
	agent.sleeping = false
	var direction_to_path: Vector2 = agent.global_position.direction_to(target.global_position)
	var distance_to: float = agent.global_position.distance_to(target.global_position)
	var speed_modifier: float = 0.0
	if (agent.soft_flux + agent.hard_flux) == 0.0 and speed_modifier != agent.zero_flux_bonus:
		speed_modifier += agent.zero_flux_bonus
	
	var velocity: Vector2 = Vector2.ZERO
	velocity = direction_to_path * agent.ship_stats.acceleration * time
	if velocity.length() < (agent.speed + speed_modifier) and distance_to > threat_radius:
		time += delta + agent.time_coefficient
	
	var brake_distance: float = (agent.linear_velocity.length() ** 2) / (2.0 * agent.ship_stats.deceleration)
	if distance_to <= threat_radius:
		agent.brake_flag = true
		velocity = -agent.linear_velocity.normalized() * agent.ship_stats.deceleration * time
	
	if agent.brake_flag == true and floor(agent.linear_velocity.length()) == 0.0:
		agent.brake_flag = false
		time = 0.0
	
	var transform_look_at: Transform2D = agent.transform.looking_at(target.global_position)
	agent.transform = agent.transform.interpolate_with(transform_look_at, agent.ship_stats.turn_rate * delta)
	velocity = velocity.limit_length(agent.speed + speed_modifier)
	agent.heur_velocity = velocity
	agent.time = time
	agent.acceleration = velocity
	return FAILURE
