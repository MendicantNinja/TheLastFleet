extends LeafAction

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 240 != 0:
		return FAILURE
	
	var registry_map: Dictionary = imap_manager.registry_map
	var player_clusters: Array = agent.player_clusters
	var player_vulnerability: Dictionary = agent.player_vulnerability
	var chunk_values: Dictionary = {}
	var target_clusters: Array = []
	for cell in player_clusters:
		var chunk_array: Array = []
		var valid_cell: bool = false
		var registry_anchor: Vector2 = Vector2(cell.y * imap_manager.max_cell_size, cell.x * imap_manager.max_cell_size)
		var registry_end: Vector2 = Vector2(registry_anchor.x + imap_manager.max_cell_size, registry_anchor.y + imap_manager.max_cell_size)
		var start_idx: Vector2i = Vector2i(registry_anchor.y / imap_manager.default_cell_size, registry_anchor.x / imap_manager.default_cell_size)
		var end_idx: Vector2i = Vector2i(registry_end.y / imap_manager.default_cell_size, registry_end.x / imap_manager.default_cell_size)
		for v_cell in player_vulnerability.keys():
			if v_cell.x >= start_idx.x && v_cell.y >= start_idx.y && v_cell.x <= end_idx.x && v_cell.y <= end_idx.y:
				valid_cell = true
				chunk_array.append(player_vulnerability[v_cell])
		
		if valid_cell == true and cell not in target_clusters:
			chunk_values[cell] = chunk_array
			target_clusters.push_back(cell)
	
	var isolated_clusters: Array = []
	for cell in chunk_values:
		var chunk_min: float = chunk_values[cell].min()
		var chunk_max: float = chunk_values[cell].max()
		if chunk_min == -1 and chunk_max == -1:
			isolated_clusters.append(cell)
	
	var vulnerable_targets: Dictionary = {}
	var isolated_targets: Array = []
	for cell in target_clusters:
		var targets = []
		var registered_agents: Array = registry_map[cell]
		for unit in registered_agents:
			if unit.is_friendly == true and unit.registry_cell in isolated_clusters:
				isolated_targets.append(unit)
			elif unit.is_friendly == true:
				targets.append(unit)
		if not targets.is_empty() and agent.heuristic_strat == globals.Strategy.OFFENSIVE:
			vulnerable_targets[cell] = targets
	
	agent.vulnerable_targets = vulnerable_targets
	agent.isolated_targets = isolated_targets
	return FAILURE
