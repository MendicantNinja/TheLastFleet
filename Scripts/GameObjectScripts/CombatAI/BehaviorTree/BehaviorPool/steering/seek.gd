extends LeafAction

var target: Ship = null
var target_position: Vector2 = Vector2.ZERO
var default_radius: int = 10

func tick(agent: Ship, blackboard: Blackboard) -> int:
	var velocity: Vector2 = Vector2.ZERO
	agent.heur_velocity = velocity
	
	if agent.ShipNavigationAgent.is_navigation_finished() == true and agent.target_position == Vector2.ZERO and agent.target_ship == null:
		agent.target_position = Vector2.ZERO
		target_position = Vector2.ZERO
		target = null
		return SUCCESS
	
	if target != agent.target_ship:
		target = agent.target_ship
	elif agent.group_leader == false and agent.target_position != target_position:
		target_position = agent.target_position
	elif agent.group_leader == true and target_position != agent.target_position:
		if imap_manager.working_maps.has(agent.group_name):
			imap_manager.working_maps.erase(agent.group_name)
		
		if not imap_manager.working_maps.has(agent.group_name):
			imap_manager.working_maps.erase(agent.group_name)
			var cell = Vector2i(agent.target_position.y / imap_manager.default_cell_size, agent.target_position.x / imap_manager.default_cell_size)
			var height: int = default_radius * imap_manager.default_cell_size
			var width: int = default_radius * imap_manager.default_cell_size
			var working_map: Imap = Imap.new(width, height, 0.0, 0.0, imap_manager.default_cell_size)
			working_map.map_type = imap_manager.MapType.INFLUENCE_MAP
			imap_manager.agent_maps[imap_manager.MapType.INFLUENCE_MAP].add_into_map(working_map, cell.y, cell.x)
			imap_manager.working_maps[agent.group_name] = working_map
		target_position = agent.target_position
	
	if target != null:
		target_position = target.global_position
	
	var direction_to_path: Vector2 = agent.global_position.direction_to(target_position)
	velocity = direction_to_path * agent.speed
	var transform_look_at: Transform2D = agent.transform.looking_at(target_position)
	agent.transform = agent.transform.interpolate_with(transform_look_at, agent.rotational_delta)
	agent.heur_velocity = velocity
	return FAILURE
