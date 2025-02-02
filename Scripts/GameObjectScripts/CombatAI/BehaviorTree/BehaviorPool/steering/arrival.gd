extends LeafAction

var target_key: StringName = &"target"
var threat_radius: float = 0.0
var target_coefficient: float = 0.95
var time_to_target: float = 0.8
var brake_distance: float = 0.0
var time: float = 0.0

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if threat_radius == 0.0:
		var radius: int = agent.template_maps[imap_manager.MapType.THREAT_MAP].width
		threat_radius = (radius * imap_manager.default_cell_size) * target_coefficient
	
	if agent.target_position == Vector2.ZERO and agent.target_ship == null:
		return FAILURE
	
	time = agent.time
	agent.sleeping = false
	var velocity: Vector2 = agent.heur_velocity
	var distance_to: float = agent.global_position.distance_to(agent.target_position)
	if agent.target_position != Vector2.ZERO and agent.target_ship == null:
		if distance_to < imap_manager.default_cell_size / 2.0:
			agent.acceleration = Vector2.ZERO
			agent.heur_velocity = Vector2.ZERO
			agent.target_position = Vector2.ZERO
			return SUCCESS
		
		#var displacement: Vector2 = agent.target_position - agent.global_position
		#var a_x: float = 0.5 * agent.acceleration.x
		#var a_y: float = 0.5 * agent.acceleration.y
		#
		#var tau_x: float = 0.0
		#var disrc_x: float = velocity.x * velocity.x - 4.0 * a_x * (-displacement.x)
		#if disrc_x < 0.0:
			#tau_x = NAN
		#else:
			#tau_x = abs((-velocity.x + sqrt(disrc_x)) / (2.0 * a_x))
		#
		#var tau_y: float = 0.0
		#var disrc_y: float = velocity.y * velocity.y - 4.0 * a_y * (-displacement.y)
		#if disrc_y < 0.0:
			#tau_y = NAN
		#else:
			#tau_y = abs((-velocity.y + sqrt(disrc_y)) / (2.0 * a_y))
		#
		#var t_approx: float = (tau_y + tau_x) / 2.0
		#if t_approx > 0.0 and t_approx != INF:
			#var decel: Vector2 = (-agent.linear_velocity * t_approx) / (2.0 * displacement)
			#var decel_vec: Vector2 = (decel * agent.heur_velocity)
			#velocity += decel_vec
		print(velocity.length())
		var brake_distance: float = (agent.linear_velocity.length() ** 2) / (2.0 * agent.ship_stats.deceleration)
		if agent.global_position.distance_to(agent.target_position) <= brake_distance:
			velocity -= agent.linear_velocity.normalized() * agent.ship_stats.deceleration
			agent.heur_velocity = velocity
			print("brake velocity: ", velocity.length())
		
	elif agent.target_ship != null:
		var target_position = agent.target_ship.global_position
		if distance_to < threat_radius:
			velocity *= time_to_target
	
	agent.acceleration = velocity
	#print(agent.linear_velocity.length())
	return FAILURE
