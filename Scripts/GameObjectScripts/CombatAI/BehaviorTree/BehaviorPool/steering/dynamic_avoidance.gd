extends LeafAction

var time_horizon: float = 4.0
var delta: float = 0.0
var debug: bool = false

@warning_ignore("confusable_local_declaration")
func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.linear_velocity == Vector2.ZERO:
		return FAILURE
	
	var neighbor_units: Array = agent.neighbor_units
	if neighbor_units.is_empty():
		return FAILURE
	
	var direction_to_path: Vector2 = agent.global_position.direction_to(agent.target_position)
	var transform_look_at: Transform2D = agent.transform.looking_at(agent.target_position)
	agent.transform = agent.transform.interpolate_with(transform_look_at, agent.ship_stats.turn_rate * delta)
	
	var group: Array = get_tree().get_nodes_in_group(agent.group_name)
	var avoid_vel: Dictionary = {}
	for neighbor in neighbor_units:
		if neighbor in group and neighbor.brake_flag == true and neighbor.target_unit == null:
			continue
		var p: Vector2 = neighbor.global_position - agent.global_position
		var v: Vector2 = agent.linear_velocity - neighbor.linear_velocity
		var r: float = agent.ShipNavigationAgent.radius + neighbor.ShipNavigationAgent.radius
		var cone: float = v.dot(v) * (p.dot(p) - r**2)
		var rel_v: float = v.dot(p) ** 2
		if rel_v <= cone:
			continue
		var projection: Vector2 = v.dot(p) / p.dot(p) * p
		var translation: Vector2 = (agent.heur_velocity - agent.linear_velocity) + (v - projection)
		var avoid_direction: Vector2 = translation.normalized()
		var avoid_velocity: Vector2 = avoid_direction * agent.ship_stats.deceleration * agent.time
		var test_avoid: float = avoid_velocity.dot(p) ** 2
		if test_avoid >= cone:
			continue
		avoid_vel[avoid_velocity.dot(avoid_velocity)] = avoid_velocity
	
	if avoid_vel.is_empty():
		return FAILURE
	
	var new_velocity: Vector2 = avoid_vel[avoid_vel.keys().min()]
	agent.acceleration = new_velocity
	return SUCCESS
