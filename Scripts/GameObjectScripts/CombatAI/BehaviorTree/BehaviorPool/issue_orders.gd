extends LeafAction

var targets_key_suffix: StringName = &" targets"

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 240 != 0:
		return FAILURE
	
	var current_group: StringName = agent.awaiting_orders.pop_back()
	var leader: Ship = null
	for unit: Ship in get_tree().get_nodes_in_group(current_group):
		if unit.group_leader == true:
			leader = unit
			break
	
	if agent.queue_orders.has(agent.posture_key):
		get_tree().call_group(current_group, &"set_posture", agent.queue_orders[agent.posture_key])
	
	if agent.queue_orders.has(agent.move_key):
		pass
		#var registry_cell: Vector2i = agent.queue_orders[agent.move_key]
		#var anchor_pos: Vector2 = Vector2(registry_cell.y * imap_manager.max_cell_size, registry_cell.x * imap_manager.max_cell_size)
		#var center_pos: Vector2 = Vector2(anchor_pos.x + imap_manager.max_cell_size / 2, anchor_pos.y + imap_manager.max_cell_size / 2)
		#leader.set_navigation_position(center_pos)
	
	if agent.queue_orders.has(agent.target_key):
		pass
	#get_tree().call_group(current_group, &"set_blackboard_data", current_group + targets_key_suffix, agent.queue_orders[agent.target_key])
	
	agent.queue_orders.clear()
	return SUCCESS
