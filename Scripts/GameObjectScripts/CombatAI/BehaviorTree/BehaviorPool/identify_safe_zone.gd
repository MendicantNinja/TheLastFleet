extends LeafAction

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.fallback_flag == false:
		return SUCCESS
	
	var safe_zone: Array = []
	for cell in agent.registry_neighborhood:
		if not imap_manager.registry_map.has(cell):
			safe_zone.append(cell)
			continue
		elif cell == agent.registry_cell:
			continue
		
		var safe: bool = true
		for unit in imap_manager.registry_map[cell]:
			if unit.is_friendly != agent.is_friendly:
				safe = false
		if safe == true:
			safe_zone.append(cell)
	
	var zone_distances: Dictionary = {}
	for zone in safe_zone:
		var dist_to: float = agent.registry_cell.distance_squared_to(zone)
		zone_distances[dist_to] = zone
	return SUCCESS
