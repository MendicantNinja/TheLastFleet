extends LeafAction

var default_radius: int = 10
var target_cell: Vector2i = Vector2i.ZERO

func tick(agent: Ship, blackboard: Blackboard) -> int:
	var velocity = Vector2.ZERO
	
	if agent.ShipNavigationAgent.is_navigation_finished() == true and agent.target_cell == Vector2i.ZERO:
		if agent.group_leader == true and imap_manager.working_maps.has(agent.group_name):
			imap_manager.working_maps.erase(agent.group_name)
		agent.rotate_angle = 0.0
		agent.move_direction = Vector2.ZERO
		agent.acceleration = velocity - agent.linear_velocity
		return SUCCESS
	
	if agent.target_cell != target_cell and agent.ShipNavigationAgent.is_navigation_finished() == true:
		var target_position: Vector2 = Vector2(agent.target_cell.y * imap_manager.default_cell_size, agent.target_cell.x * imap_manager.default_cell_size)
		agent.target_position = target_position
		target_cell = agent.target_cell
	
	if (agent.target_cell != Vector2i.ZERO or agent.target_cell != target_cell) and agent.ShipNavigationAgent.is_navigation_finished() == false:
		agent.set_navigation_position(agent.global_position)
		var target_position: Vector2 = Vector2(agent.target_cell.y * imap_manager.default_cell_size, agent.target_cell.x * imap_manager.default_cell_size)
		agent.target_position = target_position
		target_cell = agent.target_cell
	
	var cell: Vector2i = Vector2i.ZERO
	if agent.ShipNavigationAgent.is_navigation_finished() == false:
		cell = Vector2i(agent.target_position.y / imap_manager.default_cell_size, agent.target_position.x / imap_manager.default_cell_size)
		
		if agent.group_leader == true and not agent.group_name.is_empty() and not imap_manager.working_maps.has(agent.group_name):
			var cell_position: Vector2 = Vector2(cell.y * imap_manager.default_cell_size, cell.x * imap_manager.default_cell_size)
			agent.set_navigation_position(cell_position)
			var height: int = default_radius * imap_manager.default_cell_size
			var width: int = default_radius * imap_manager.default_cell_size
			var working_map: Imap = Imap.new(width, height, 0.0, 0.0, imap_manager.default_cell_size)
			working_map.map_type = imap_manager.MapType.INFLUENCE_MAP
			imap_manager.agent_maps[imap_manager.MapType.INFLUENCE_MAP].add_into_map(working_map, cell.y, cell.x)
			imap_manager.working_maps[agent.group_name] = working_map
			globals.generate_group_target_positions(agent)
	
	if agent.ShipNavigationAgent.is_navigation_finished() == false and imap_manager.working_maps.has(agent.group_name):
		var working_map = imap_manager.working_maps[agent.group_name]
		if Engine.get_physics_frames() % 120 == 0:
			imap_manager.agent_maps[imap_manager.MapType.INFLUENCE_MAP].add_into_map(working_map, cell.y, cell.x)
	
	return FAILURE
