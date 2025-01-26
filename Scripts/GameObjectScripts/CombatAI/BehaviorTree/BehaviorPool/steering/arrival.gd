extends LeafAction

var target_key: StringName = &"target"
var desired_distance: float = 0.0
var threat_radius: float = 0.0
var target_coefficient: float = 0.95
var time_to_target: float = 0.8
var delta: float = 0.0

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if desired_distance == 0.0:
		desired_distance = (agent.template_maps[imap_manager.MapType.OCCUPANCY_MAP].width - 1) * imap_manager.default_cell_size / 2
	if threat_radius == 0.0:
		var radius: int = agent.template_maps[imap_manager.MapType.THREAT_MAP].width
		threat_radius = (radius * imap_manager.default_cell_size) * target_coefficient
	if delta == 0.0:
		delta = get_physics_process_delta_time()
	
	if agent.target_position == Vector2.ZERO and agent.target_ship == null:
		return FAILURE
	
	var velocity: Vector2 = agent.heur_velocity
	var distance_to: float = agent.global_position.distance_to(agent.target_position)
	if agent.target_position != Vector2.ZERO and agent.target_ship == null:
		if floor(agent.acceleration) == Vector2.ZERO and distance_to < imap_manager.default_cell_size:
			agent.target_position = Vector2.ZERO
		var displacement: Vector2 = agent.target_position - agent.global_position
		var a_x: float = 0.5 * agent.acceleration.x
		var a_y: float = 0.5 * agent.acceleration.y
		
		var tau_x1: float = 0.0
		var tau_x2: float = 0.0
		var disrc_x: float = velocity.x * velocity.x - 4.0 * a_x * (-displacement.x)
		if disrc_x < 0.0:
			tau_x1 = NAN
			tau_x2 = NAN
		else:
			tau_x1 = (-velocity.x + sqrt(disrc_x)) / (2.0 * a_x)
			tau_x2 = (velocity.x - sqrt(disrc_x)) / (2.0 * a_x)
		
		var tau_y1: float = 0.0
		var tau_y2: float = 0.0
		var disrc_y: float = velocity.y * velocity.y - 4.0 * a_y * (-displacement.y)
		if disrc_y < 0.0:
			tau_y1 = NAN
			tau_y2 = NAN
		else:
			tau_y1 = (-velocity.y + sqrt(disrc_y)) / (2.0 * a_y)
			tau_y2 = (velocity.y - sqrt(disrc_y)) / (2.0 * a_y)
		
		var tau1: float = max(tau_x1, tau_x2)
		var tau2: float = max(tau_y1, tau_y2)
		var t_approx: float = min(tau1, tau2)
		if t_approx > 0.0 and t_approx != INF:
			var decel: Vector2 = (-agent.linear_velocity * t_approx) / (2.0 * displacement)
			var decel_vec: Vector2 = (decel * agent.heur_velocity)
			velocity += decel_vec
	elif agent.target_ship != null:
		var target_position = agent.target_ship.global_position
		if distance_to < threat_radius:
			velocity *= time_to_target
	
	agent.sleeping = false
	agent.acceleration = velocity
	print(agent.acceleration.length())
	return FAILURE
