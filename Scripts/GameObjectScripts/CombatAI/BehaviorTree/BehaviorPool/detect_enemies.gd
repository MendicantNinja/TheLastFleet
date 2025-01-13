extends LeafAction

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 120 != 0:
		return FAILURE
	
	var enemy_presence: Array = get_tree().get_nodes_in_group(&"friendly")
	
	if enemy_presence.is_empty():
		return SUCCESS
	
	enemy_presence = []
	var enemy_density: Dictionary = {}
	var registry_map: Dictionary = imap_manager.registry_map
	for cell in registry_map:
		var influence_density: float = 0.0
		var registered_agents: Array = registry_map[cell]
		for unit in registered_agents:
			if unit.is_friendly == true:
				influence_density += unit.approx_influence
			if unit.is_friendly == true and not enemy_presence.has(cell):
				enemy_presence.push_back(cell)
		if influence_density > 0.0:
			enemy_density[cell] = influence_density
	
	agent.enemy_clusters = enemy_density.keys()
	return FAILURE
