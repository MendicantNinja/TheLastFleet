extends LeafAction

var time_horizon: float = 4.0
var delta: float = 0.0
var debug: bool = false
var time: float = 0.0
var avoid_unit: Ship = null

@warning_ignore("confusable_local_declaration")
func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.sleeping == true or floor(agent.linear_velocity.length()) == 0.0:
		return FAILURE
	
	if delta == 0.0:
		delta = get_physics_process_delta_time()
	
	var neighbor_units: Array = agent.neighbor_units
	if neighbor_units.is_empty():
		return FAILURE
	
	var group: Array = get_tree().get_nodes_in_group(agent.group_name)
	var avoid_vel: Dictionary = {}
	var avoid_neighbors: Dictionary = {}
	for neighbor in neighbor_units:
		if neighbor in group and neighbor.brake_flag == true and neighbor.target_unit == null:
			continue
		var p: Vector2 = neighbor.global_position - agent.global_position
		var v: Vector2 = agent.linear_velocity - neighbor.linear_velocity
		var r: float = agent.ShipNavigationAgent.radius + neighbor.ShipNavigationAgent.radius
		var distance_sq: float = agent.global_position.distance_squared_to(neighbor.global_position)
		var cone: float = v.dot(v) * (p.dot(p) - r**2)
		var rel_v: float = (v.dot(p) ** 2)
		if rel_v <= cone:
			continue
		var projection: Vector2 = (v.dot(p) / (p.dot(p) + 1e-6)) * p
		var translation: Vector2 = agent.heur_velocity + (v - projection)
		if roundf(neighbor.linear_velocity.length()) == 0.0:
			translation = (agent.heur_velocity - agent.linear_velocity) + (v - projection)
		var avoid_direction: Vector2 = translation.normalized()
		var avoid_velocity: Vector2 = avoid_direction * agent.speed * agent.time
		var test_avoid: float = avoid_velocity.dot(p) ** 2
		if test_avoid >= cone:
			continue
		avoid_vel[distance_sq] = avoid_velocity.limit_length(agent.speed)
		avoid_neighbors[distance_sq] = neighbor
	
	if avoid_vel.is_empty():
		return FAILURE
	
	var min_dist: float = avoid_vel.keys().min()
	var new_velocity: Vector2 = avoid_vel[avoid_vel.keys().min()]
	agent.heur_velocity = new_velocity
	agent.acceleration = new_velocity
	return FAILURE
