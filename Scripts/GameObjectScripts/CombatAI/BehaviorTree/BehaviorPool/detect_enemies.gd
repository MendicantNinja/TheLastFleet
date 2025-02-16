extends LeafAction

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 120 != 0:
		return FAILURE
	
	var enemy_presence: Array = get_tree().get_nodes_in_group(&"friendly")
	var unit_presence: Array = get_tree().get_nodes_in_group(&"enemy")
	if enemy_presence.is_empty() or unit_presence.is_empty():
		return SUCCESS
	
	unit_presence = []
	enemy_presence = []
	var registry_map: Dictionary = imap_manager.registry_map
	for cell in registry_map:
		var registered_agents: Array = registry_map[cell]
		for unit in registered_agents:
			if unit.is_friendly == false and not unit_presence.has(cell):
				unit_presence.push_back(cell)
			if unit.is_friendly == true and not enemy_presence.has(cell):
				enemy_presence.push_back(cell)
	
	agent.unit_clusters = unit_presence
	agent.enemy_clusters = enemy_presence
	return FAILURE
