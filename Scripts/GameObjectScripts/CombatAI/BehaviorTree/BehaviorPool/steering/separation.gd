extends LeafAction

var fof_radius: float = 0.0
var rad_coe: float = 3.0

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if fof_radius == 0.0:
		fof_radius = agent.ShipNavigationAgent.radius * rad_coe
	
	var neighbors: Array = agent.neighbor_units
	var friendly_neighbors: Array = []
	for unit in neighbors:
		if agent.is_friendly == true and unit.is_friendly == true:
			friendly_neighbors.append(unit)
		elif agent.is_friendly == false and unit.is_friendly == false:
			friendly_neighbors.append(unit)
	
	var velocity: Vector2 = Vector2.ZERO
	var strafe_directions: Array = []
	var agent_fof: float = fof_radius * fof_radius
	for neighbor in friendly_neighbors:
		var neighbor_fof: float = neighbor.ShipNavigationAgent.radius * rad_coe
		neighbor_fof *= neighbor_fof
		var square_dist: float = neighbor.global_position.distance_squared_to(agent.global_position)
		if square_dist > (agent_fof + neighbor_fof):
			continue
		var rel_pos: Vector2 = neighbor.global_position - agent.global_position
		var euc_dist: float = sqrt(square_dist)
		var chord_base: float = (agent_fof - neighbor_fof + square_dist) / (2 * euc_dist)
		var chord_height: float = sqrt(agent_fof - chord_base**2)
		var p2: Vector2 = agent.global_position + (chord_base * rel_pos) / euc_dist
		var intersect_x1: float = p2.x + (chord_height * rel_pos.y) / euc_dist
		var intersect_y1: float = p2.y - (chord_height * rel_pos.x) / euc_dist
		var intersect_x2: float = p2.x - (chord_height * rel_pos.y) / euc_dist
		var intersect_y2: float = p2.y + (chord_height * rel_pos.x) / euc_dist
		var intersect1: Vector2 = agent.to_local(Vector2(intersect_x1, intersect_y1)).normalized()
		var intersect2: Vector2 =  agent.to_local(Vector2(intersect_x2, intersect_y2)).normalized()
		var fof_arc1: float = agent.transform.x.angle_to(intersect1)
		var fof_arc2: float = agent.transform.x.angle_to(intersect2)
		var agent_dir: float = agent.transform.x.angle()
		var abs_dir: float = abs(agent_dir)
		var norm_arc: float = intersect1.angle_to(-intersect2)
		if fof_arc1 <= norm_arc and fof_arc2 <= norm_arc:
			strafe_directions.append(intersect1)
		else:
			strafe_directions.append(intersect2)
	
	if strafe_directions.is_empty() == true:
		return FAILURE
	
	var sum_direction: Vector2 = Vector2.ZERO
	var length: float = 0.0
	for direction in strafe_directions:
		sum_direction += direction
		length += sum_direction.length()
	
	var speed: float = agent.ship_stats.acceleration
	var speed_modifier: float = 0.0
	if (agent.soft_flux + agent.hard_flux) == 0.0:
		speed += agent.zero_flux_bonus
	
	sum_direction /= length
	velocity = sum_direction * speed * agent.time
	velocity = velocity.limit_length(speed)
	agent.heur_velocity = velocity
	agent.acceleration = velocity
	return FAILURE
