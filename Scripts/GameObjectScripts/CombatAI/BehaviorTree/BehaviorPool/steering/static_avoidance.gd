extends LeafAction

var time_horizon: float = 8.0

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.heur_velocity != Vector2.ZERO and agent.target_cell != Vector2i.ZERO:
		return SUCCESS
	
	var neighbor_units: Array = agent.neighbor_units
	if neighbor_units.is_empty():
		return FAILURE
	
	var time_to_collision: float = INF
	var avoid_unit: Dictionary = {}
	var tau1: float = 0.0
	var tau2: float = 0.0
	for unit: Ship in neighbor_units:
		var r: float = unit.ShipNavigationAgent.radius + agent.ShipNavigationAgent.radius
		var w: Vector2 = agent.global_position - unit.global_position
		var c: float = w.dot(w) - r * r # c
		if c <= 0:
			continue
		var v: Vector2 = unit.heur_velocity - agent.heur_velocity
		var a: float = v.dot(v) # dot product of difference in velocities
		var b: float = 2 * w.dot(v) # dot product of the differences in position and difference in velocities
		if unit.heur_velocity == Vector2.ZERO:
			continue
		var disrc: float = b * b - a * c # b^2 - a*c
		if disrc <= 0:
			continue
		tau1 = (b - sqrt(disrc)) / a
		tau2 = (b + sqrt(disrc)) / a
		if tau1 <= 0 and tau2 <= 0:
			continue
		var min_tau: float = min(tau1, tau2)
		avoid_unit[unit] = min_tau
	
	if avoid_unit.is_empty():
		return SUCCESS
	
	var net_force: Vector2 = Vector2.ZERO
	for unit in avoid_unit:
		var tau = avoid_unit[unit]
		var lol: Vector2 = agent.global_position.direction_to(unit.global_position)
		var avoid_direction: Vector2 = agent.global_position + agent.linear_velocity * tau - unit.global_position - unit.heur_velocity * tau
		avoid_direction = avoid_direction.normalized()
		var mag: float = 0.0
		mag = agent.movement_delta
		net_force += avoid_direction * agent.movement_delta * 2
	
	agent.sleeping = false
	
	agent.acceleration = Vector2(net_force.x, -net_force.y)
	
	return FAILURE
