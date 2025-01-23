extends LeafAction

var target_key: StringName = &"target"
var desired_distance: float = 0.0
var threat_radius: float = 0.0
var target_coefficient: float = 0.95
var time_to_target: float = 0.9

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if desired_distance == 0.0:
		desired_distance = (agent.template_maps[imap_manager.MapType.OCCUPANCY_MAP].width - 1) * imap_manager.default_cell_size
	if threat_radius == 0.0:
		var radius: int = agent.template_maps[imap_manager.MapType.THREAT_MAP].width
		threat_radius = (radius * imap_manager.default_cell_size) * target_coefficient
	
	if agent.ShipNavigationAgent.is_navigation_finished() == true and agent.target_cell == Vector2i.ZERO and agent.target_ship == null:
		return FAILURE
	
	agent.sleeping = false
	var velocity: Vector2 = agent.heur_velocity
	var distance_to: float = agent.global_position.distance_to(agent.target_position)
	if agent.ShipNavigationAgent.is_navigation_finished() == true and agent.target_ship == null:
		if distance_to < desired_distance / 2:
			velocity *= time_to_target
		if agent.global_position.distance_to(agent.target_position) < imap_manager.default_cell_size / 8:
			agent.target_position = Vector2.ZERO
			agent.target_cell = Vector2i.ZERO
	elif agent.target_ship != null:
		var target_position = agent.target_ship.global_position
		if distance_to < threat_radius:
			velocity *= time_to_target
	
	agent.acceleration = velocity - agent.linear_velocity
	
	return FAILURE
