extends LeafAction

var time_horizon: float = 4.0

@warning_ignore("confusable_local_declaration")
func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.heur_velocity == Vector2.ZERO:
		return FAILURE
	
	var neighbor_units: Array = agent.neighbor_units
	if neighbor_units.is_empty():
		return FAILURE
	
	var time_to_collision: float = INF
	var avoid_unit: Dictionary = {}
	var tau1: float = 0.0
	var tau2: float = 0.0
	for unit: Ship in neighbor_units:
		if unit == agent:
			continue
		var r: float = agent.ShipNavigationAgent.radius + unit.ShipNavigationAgent.radius
		var w: Vector2 = (unit.global_position - agent.global_position)
		var c: float = unit.global_position.distance_to(agent.global_position) - r # c
		if c <= 0:
			continue
		c = w.dot(w) - r * r
		var v: Vector2 = agent.heur_velocity - unit.heur_velocity
		if unit.heur_velocity == Vector2.ZERO:
			v = agent.heur_velocity - unit.linear_velocity
		var a: float = v.dot(v) # dot product of difference in velocities
		var b: float = 2.0 * w.dot(v) # dot product of the differences in position and difference in velocities
		var disrc: float = b * b - a * c # b^2 - a*c
		if disrc <= 0:
			continue
		tau1 = (b - sqrt(disrc)) / a
		tau2 = (b + sqrt(disrc)) / a
		if tau1 <= 0.0 and tau2 <= 0.0:
			continue
		var min_tau: float = min(tau1, tau2)
		if min_tau > time_horizon:
			continue
		avoid_unit[min_tau] = unit
	
	if avoid_unit.is_empty():
		return FAILURE
	
	var net_force: Vector2 = agent.heur_velocity
	for tau in avoid_unit:
		var unit = avoid_unit[tau]
		var avoid_direction: Vector2 = agent.global_position + agent.heur_velocity * tau - unit.global_position - unit.heur_velocity * tau
		if unit.heur_velocity == Vector2.ZERO:
			avoid_direction = agent.global_position + agent.heur_velocity * tau - unit.global_position - unit.linear_velocity * tau
		avoid_direction = avoid_direction.normalized()
		var mag: float = 0.0
		mag = agent.movement_delta
		net_force += (avoid_direction * mag)
	
	agent.heur_velocity = Vector2.ONE
	agent.acceleration = net_force
	return FAILURE
