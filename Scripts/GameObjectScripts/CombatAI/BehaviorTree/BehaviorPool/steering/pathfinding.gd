extends LeafAction

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.target_unit != null:
		if agent.target_position != Vector2.ZERO:
			agent.target_position = Vector2.ZERO
		return SUCCESS
	
	if agent.ShipNavigationAgent.is_navigation_finished() == true and agent.target_position == Vector2.ZERO:
		if agent.group_leader == true and imap_manager.working_maps.has(agent.group_name):
			imap_manager.working_maps.erase(agent.group_name)
		return SUCCESS
	
	var cell: Vector2i = Vector2i.ZERO
	if agent.ShipNavigationAgent.is_navigation_finished() == false and agent.group_leader == true and not agent.group_name.is_empty():
		globals.generate_group_target_positions(agent)
	
	if agent.group_leader == true and imap_manager.working_maps.has(agent.group_name):
		var working_map = imap_manager.working_maps[agent.group_name]
		if Engine.get_physics_frames() % 120 == 0:
			imap_manager.agent_maps[imap_manager.MapType.INFLUENCE_MAP].add_into_map(working_map, cell.y, cell.x)
	
	return FAILURE
