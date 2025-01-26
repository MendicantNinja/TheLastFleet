extends LeafAction

var target_key: StringName = &"target"
var desired_distance: float = 0.0
var threat_radius: float = 0.0
var target_coefficient: float = 0.95
var time_to_target: float = 0.8

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if desired_distance == 0.0:
		desired_distance = (agent.template_maps[imap_manager.MapType.OCCUPANCY_MAP].width - 1) * imap_manager.default_cell_size / 2
	if threat_radius == 0.0:
		var radius: int = agent.template_maps[imap_manager.MapType.THREAT_MAP].width
		threat_radius = (radius * imap_manager.default_cell_size) * target_coefficient
	
	if agent.target_position == Vector2.ZERO and agent.target_ship == null:
		return FAILURE
	
	var velocity: Vector2 = agent.heur_velocity
	var distance_to: float = agent.global_position.distance_to(agent.target_position)
	if agent.target_position != Vector2.ZERO and agent.target_ship == null:
		var time_to_arrival: float = 0.0
		
		if distance_to < desired_distance:
			velocity *= time_to_target
		if distance_to < imap_manager.default_cell_size / 5:
			agent.target_position = Vector2.ZERO
	elif agent.target_ship != null:
		var target_position = agent.target_ship.global_position
		if distance_to < threat_radius:
			velocity *= time_to_target
	
	agent.sleeping = false
	agent.acceleration = velocity - agent.linear_velocity
	
	return FAILURE
