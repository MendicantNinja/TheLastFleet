extends LeafAction

# strafe: useful in a wide variety of combat situations
# Use Cases:
# - Give other ships attacking a target space
# - Moving out of a friendly ship's field of fire

var fof_radius: float = 0.0

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if fof_radius == 0.0:
		fof_radius = agent.ShipNavigationAgent.radius * 2.0
	
	var neighbors: Array = agent.neighbor_units
	var friendly_neighbors: Array = []
	for unit in neighbors:
		if agent.is_friendly == true and unit.is_friendly == true:
			friendly_neighbors.append(unit)
		elif agent.is_friendly == false and unit.is_friendly == false:
			friendly_neighbors.append(unit)
	
	var velocity: Vector2 = Vector2.ZERO
	var strafe_directions: Array = []
	if agent.target_in_range == true:
		var fof_square: float = fof_radius * fof_radius
		var valid_neighbor: Array = []
		for neighbor in friendly_neighbors:
			var neighbor_fof: float = neighbor.ShipNavigationAgent.radius * 2.0
			neighbor_fof *= neighbor_fof
			var dist_to: float = neighbor.global_position.distance_squared_to(agent.global_position)
			if dist_to > (fof_square + neighbor_fof) or dist_to < abs(fof_square - neighbor_fof):
				continue
			valid_neighbor.append(neighbor)
			var a: float = (fof_square - neighbor_fof + dist_to) / (2 * dist_to)
			var h: float = sqrt(fof_square - a**2)
			var p2: Vector2 = agent.global_position - a * ((neighbor.global_position - agent.global_position) / sqrt(dist_to))
			var intersect_x1: float = p2.x + h * (neighbor.global_position.y - agent.global_position.y) / dist_to
			var intersect_y1: float = p2.y - h * (neighbor.global_position.x - agent.global_position.x) / dist_to
			var intersect_x2: float = p2.x - h * (neighbor.global_position.y - agent.global_position.y) / dist_to
			var intersect_y2: float = p2.y + h * (neighbor.global_position.x - agent.global_position.x) / dist_to
			var norm_intersect1: Vector2 = Vector2(intersect_x1, intersect_y1).normalized()
			var norm_intersect2: Vector2 = Vector2(intersect_x2, intersect_y2).normalized()
			print(agent.name)
			print((180/PI) * (Vector2(1.0, 0.0).angle_to(agent.transform.x)))
			print((180/PI) * (agent.transform.x.angle_to(norm_intersect1)))
			print((180/PI) * (agent.transform.x.angle_to(norm_intersect2)))
			pass
		pass
	return FAILURE
