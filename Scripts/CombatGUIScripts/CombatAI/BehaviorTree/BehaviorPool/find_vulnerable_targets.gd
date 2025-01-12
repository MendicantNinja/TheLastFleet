extends LeafAction

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 240 != 0:
		return FAILURE
	
	var registry_map: Dictionary = imap_manager.registry_map
	var enemy_vulnerability: Array = agent.enemy_vulnerability
	var target_chunks: Array = []
	for cell in registry_map:
		var valid_cell: bool = false
		var registry_anchor: Vector2 = Vector2(cell.y * imap_manager.max_cell_size, cell.x * imap_manager.max_cell_size)
		var registry_end: Vector2 = Vector2(registry_anchor.x + imap_manager.max_cell_size, registry_anchor.y + imap_manager.max_cell_size)
		var start_idx: Vector2i = Vector2i(registry_anchor.y / imap_manager.default_cell_size, registry_anchor.x / imap_manager.default_cell_size)
		var end_idx: Vector2i = Vector2i(registry_end.y / imap_manager.default_cell_size, registry_end.x / imap_manager.default_cell_size)
		for v_cell in enemy_vulnerability:
			if v_cell.x >= start_idx.x && v_cell.y >= start_idx.y && v_cell.x <= end_idx.x && v_cell.y <= end_idx.y:
				valid_cell = true
		
		if valid_cell == true and cell not in target_chunks:
			target_chunks.push_back(cell)
	
	var vulnerable_targets: Dictionary = agent.vulnerable_targets
	for chunk in target_chunks:
		var registered_agents: Array = registry_map[chunk]
		for unit in registered_agents:
			if vulnerable_targets.has(unit.imap_cell) and vulnerable_targets[unit.imap_cell] == unit:
				continue
			vulnerable_targets[unit.imap_cell] = unit
	
	for target in vulnerable_targets:
		var unit = vulnerable_targets[target]
		if unit == null:
			vulnerable_targets.erase(unit.imap_cell)
	
	agent.vulnerable_targets = vulnerable_targets
	return FAILURE
