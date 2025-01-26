extends LeafAction

var time_horizon: float = 1.0

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.heur_velocity != Vector2.ZERO and agent.target_position != Vector2.ZERO:
		agent.avoid_flag = false
		return SUCCESS
	
	var neighbor_units: Array = agent.neighbor_units
	if neighbor_units.is_empty():
		agent.avoid_flag = false
		return SUCCESS
	
	var active_units: Array = []
	for unit in neighbor_units:
		if unit == agent:
			continue
		if unit.linear_velocity != Vector2.ZERO:
			active_units.append(unit)
	
	if active_units.is_empty():
		agent.avoid_flag = false
		return SUCCESS
	
	var time_to_collision: float = INF
	var avoid_unit: Dictionary = {}
	var tau1: float = 0.0
	var tau2: float = 0.0
	for unit: Ship in active_units:
		if unit.linear_velocity == Vector2.ZERO:
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
		var disrc: float = b * b - 4.0 * a * c # b^2 - a*c
		if disrc <= 0:
			continue
		tau1 = (b - sqrt(disrc)) / a
		tau2 = (b + sqrt(disrc)) / a
		if tau1 < 0.0 and tau2 < 0.0:
			continue
		var min_tau: float = min(tau1, tau2)
		if min_tau > time_horizon or min_tau < 0.0:
			continue
		print(agent.name)
		print("tau: ", min_tau)
		avoid_unit[min_tau] = unit
	
	if avoid_unit.is_empty():
		agent.avoid_flag = false
		return SUCCESS
	agent.avoid_flag = true
	
	var net_force: Vector2 = Vector2.ZERO
	for tau in avoid_unit:
		var unit = avoid_unit[tau]
		var lol: Vector2 = agent.global_position.direction_to(unit.global_position)
		var avoid_direction: Vector2 = agent.global_position + agent.linear_velocity * tau - unit.global_position - unit.heur_velocity - unit.linear_velocity * tau
		avoid_direction = avoid_direction.normalized()
		var funny = avoid_direction.dot(avoid_direction)
		avoid_direction = avoid_direction.rotated(funny)
		net_force += avoid_direction * agent.speed
	net_force /= avoid_unit.size()
	agent.sleeping = false
	agent.acceleration = net_force
	return RUNNING
