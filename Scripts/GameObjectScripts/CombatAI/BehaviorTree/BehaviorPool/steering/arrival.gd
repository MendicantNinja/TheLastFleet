extends LeafAction

var target_key: StringName = &"target"
var threat_radius: float = 0.0
var target_coefficient: float = 0.95
var time_to_target: float = 0.8

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if threat_radius == 0.0:
		var radius: int = agent.template_maps[imap_manager.MapType.THREAT_MAP].width
		threat_radius = (radius * imap_manager.default_cell_size) * target_coefficient
	
	if agent.target_position == Vector2.ZERO and agent.target_ship == null:
		return FAILURE
	
	agent.sleeping = false
	var velocity: Vector2 = agent.heur_velocity
	var distance_to: float = agent.global_position.distance_to(agent.target_position)
	if agent.target_position != Vector2.ZERO and agent.target_ship == null:
		if distance_to < imap_manager.default_cell_size / 2.0:
			agent.acceleration = Vector2.ZERO
			agent.heur_velocity = Vector2.ZERO
			agent.target_position = Vector2.ZERO
			return SUCCESS
		
		var tau_x: float = -agent.heur_velocity.x / agent.acceleration.x
		var tau_y: float = -agent.heur_velocity.y / agent.acceleration.y
		var tau: float = -agent.heur_velocity.dot(agent.heur_velocity) / agent.acceleration.dot(agent.acceleration)
		#var displacement: Vector2 = agent.target_position - agent.global_position
		#var a_x: float = 0.5 * agent.acceleration.x
		#var a_y: float = 0.5 * agent.acceleration.y
		#
		#var tau_x1: float = 0.0
		#var tau_x2: float = 0.0
		#var disrc_x: float = velocity.x * velocity.x - 4.0 * a_x * (-displacement.x)
		#if disrc_x < 0.0:
			#tau_x1 = NAN
			#tau_x2 = NAN
		#else:
			#tau_x1 = (-velocity.x + sqrt(disrc_x)) / (2.0 * a_x)
			#tau_x2 = (velocity.x - sqrt(disrc_x)) / (2.0 * a_x)
		#
		#var tau_y1: float = 0.0
		#var tau_y2: float = 0.0
		#var disrc_y: float = velocity.y * velocity.y - 4.0 * a_y * (-displacement.y)
		#if disrc_y < 0.0:
			#tau_y1 = NAN
			#tau_y2 = NAN
		#else:
			#tau_y1 = (-velocity.y + sqrt(disrc_y)) / (2.0 * a_y)
			#tau_y2 = (velocity.y - sqrt(disrc_y)) / (2.0 * a_y)
		#
		#var tau1: float = max(tau_x1, tau_x2)
		#var tau2: float = max(tau_y1, tau_y2)
		#var t_approx: float = tau1 + tau2
		#if t_approx > 0.0 and t_approx != INF:
			#var decel: Vector2 = (-agent.linear_velocity * t_approx) / (2.0 * displacement)
			#var decel_vec: Vector2 = (decel * agent.heur_velocity)
			#velocity += decel_vec
			#print(t_approx)
		
		#var displacement: Vector2 = agent.target_position - agent.global_position
		#displacement = agent.to_local(displacement)
		#var norm_accel: Vector2 = agent.acceleration.normalized()
		#var a: Vector2 = 0.5 * agent.acceleration
		#var b: float = velocity.dot(velocity) / velocity.dot(agent.acceleration)
		#var c: float = velocity.dot(velocity) / (2.0 * agent.acceleration.dot(agent.acceleration)) - velocity.dot(displacement) / agent.acceleration.dot(displacement)
		#var disrc: float = b * b - 4.0 * c
		#var shitsngiggles: Vector2 = agent.heur_velocity - a
		#print(shitsngiggles)
		#if disrc > 0.0:
			#var t1: float = (-b + sqrt(disrc)) / 2
			#var t2: float = (-b - sqrt(disrc)) / 2
			#if t1 >= 0.0 or t2 >= 0.0:
				#var tau: float = max(t1, t2)
				#var decel: Vector2 = (-agent.heur_velocity * tau) / (2.0 * displacement)
				#var decel_vec: Vector2 = (decel * agent.heur_velocity)
				#velocity += decel_vec
				#
		
	elif agent.target_ship != null:
		var target_position = agent.target_ship.global_position
		if distance_to < threat_radius:
			velocity *= time_to_target
	
	agent.acceleration = velocity
	return FAILURE
