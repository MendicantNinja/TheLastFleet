extends LeafAction

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 120 != 0:
		return FAILURE
	
	var influence_map: Imap = imap_manager.current_maps[imap_manager.MapType.INFLUENCE_MAP]
	var fake_tension_map: Imap = imap_manager.current_maps[imap_manager.MapType.TENSION_MAP]
	var tension_map: Imap = imap_manager.tension_map
	var vulnerability_map: Imap = imap_manager.vulnerability_map
	for m in range(0, vulnerability_map.height, 1):
		for n in range(0, vulnerability_map.width, 1):
			var tension_value: float = 0.0
			var vuln_value: float = 0.0
			if fake_tension_map.map_grid[m][n] == 0.0 and influence_map.map_grid[m][n] == 0.0:
				tension_map.map_grid[m][n] = tension_value
				tension_map.update_grid_value.emit(m, n, tension_value)
				vulnerability_map.map_grid[m][n] = vuln_value
				vulnerability_map.update_grid_value.emit(m, n, vuln_value)
				continue
			tension_value = max(0, fake_tension_map.map_grid[m][n] - abs(influence_map.map_grid[m][n]))
			vuln_value = tension_value - abs(influence_map.map_grid[m][n])
			tension_map.map_grid[m][n] = tension_value
			vulnerability_map.map_grid[m][n] = vuln_value
			tension_map.update_grid_value.emit(m, n, tension_value)
			vulnerability_map.update_grid_value.emit(m, n, vuln_value)
	
	return FAILURE
