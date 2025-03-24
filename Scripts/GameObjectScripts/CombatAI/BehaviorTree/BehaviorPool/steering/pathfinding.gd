extends LeafAction

func tick(agent: Ship, blackboard: Blackboard) -> int:
	#if NavigationServer2D.map_get_iteration_id(agent.ShipNavigationAgent.get_navigation_map()) == 0:
		#return SUCCESS
	
	if Engine.get_physics_frames() % 720 == 0 and agent.successful_deploy == false and agent.group_leader == true:
		var group: Array = get_tree().get_nodes_in_group(agent.group_name)
		if group.size() == 1:
			agent.group_remove(agent.group_name)
			agent.ships_deployed.emit()
	
	if agent.target_unit != null or agent.target_position == Vector2.ZERO:
		return SUCCESS
	
	#if agent.ShipNavigationAgent.is_navigation_finished() == true and agent.target_position == Vector2.ZERO:
		#if agent.group_leader == true and imap_manager.working_maps.has(agent.group_name):
			#imap_manager.working_maps.erase(agent.group_name)
	
	#var cell: Vector2i = Vector2i.ZERO
	if agent.ShipNavigationAgent.is_navigation_finished() == false and agent.group_leader == true:
		globals.generate_group_target_positions(agent)
		agent.ShipNavigationAgent.set_target_position(agent.global_position)
	
	#if agent.group_leader == true and imap_manager.working_maps.has(agent.group_name):
		#var working_map = imap_manager.working_maps[agent.group_name]
		#if Engine.get_physics_frames() % 120 == 0:
			#imap_manager.agent_maps[imap_manager.MapType.INFLUENCE_MAP].add_into_map(working_map, cell.y, cell.x)
	
	return FAILURE
