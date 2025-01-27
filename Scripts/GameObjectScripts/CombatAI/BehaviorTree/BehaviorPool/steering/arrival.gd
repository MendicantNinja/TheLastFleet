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
		
		if distance_to < imap_manager.default_cell_size:
			agent.acceleration = agent.heur_velocity - agent.linear_velocity
			return FAILURE
		
		var displacement: Vector2 = agent.target_position - agent.global_position
		var b: float = velocity.dot(velocity) / velocity.dot(agent.acceleration)
		var c: float = velocity.dot(velocity) / (2 * agent.acceleration.dot(agent.acceleration)) - velocity.dot(displacement) / agent.acceleration.dot(displacement)
		var disrc: float = b * b - 4.0 * c
		if disrc > 0.0:
			var t1: float = (-b + sqrt(disrc)) / 2
			var t2: float = (-b - sqrt(disrc)) / 2
			if t1 >= 0.0 or t2 >= 0.0:
				var tau: float = max(t1, t2)
				var decel: Vector2 = (-agent.linear_velocity * tau) / (2.0 * displacement)
				var decel_vec: Vector2 = (decel * agent.heur_velocity)
				velocity += decel_vec
		
	elif agent.target_ship != null:
		var target_position = agent.target_ship.global_position
		if distance_to < threat_radius:
			velocity *= time_to_target
	
	agent.acceleration = velocity
	return FAILURE
