extends LeafAction

func tick(agent: GDAdmiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 120 != 0:
		return FAILURE
	
	var player_presence: Array = get_tree().get_nodes_in_group(&"friendly")
	var unit_presence: Array = get_tree().get_nodes_in_group(&"enemy")
	if player_presence.is_empty() or unit_presence.is_empty():
		return SUCCESS
	
	unit_presence = []
	player_presence = []
	var registry_map: Dictionary = imap_manager.registry_map
	for cell in registry_map:
		var registered_agents: Array = registry_map[cell]
		for unit in registered_agents:
			if unit.is_friendly == false and not unit_presence.has(cell):
				unit_presence.push_back(cell)
			if unit.is_friendly == true and not player_presence.has(cell):
				player_presence.push_back(cell)
	
	agent.unit_clusters = unit_presence
	agent.player_clusters = player_presence
	return FAILURE
