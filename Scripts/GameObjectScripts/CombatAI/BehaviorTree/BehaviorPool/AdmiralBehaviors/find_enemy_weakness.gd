extends LeafAction

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 180 != 0:
		return FAILURE
	
	var weighted_imap: Imap = imap_manager.weighted_imap
	var influence_map: Imap = imap_manager.agent_maps[imap_manager.MapType.INFLUENCE_MAP]
	var fake_tension_map: Imap = imap_manager.agent_maps[imap_manager.MapType.TENSION_MAP]
	var tension_map: Imap = imap_manager.tension_map
	var vulnerability_map: Imap = imap_manager.vulnerability_map
	var enemy_influence_extrema: Dictionary = {}
	var player_vulnerability: Dictionary = {}
	for m in range(0, vulnerability_map.height, 1):
		
		var tension_max: float = snappedf(fake_tension_map.map_grid[m].max(), 0.01)
		var tension_min: float = snappedf(fake_tension_map.map_grid[m].min(), 0.01)
		var imap_max: float = snappedf(influence_map.map_grid[m].max(), 0.01)
		var imap_min: float = snappedf(influence_map.map_grid[m].min(), 0.01)
		if tension_max == 0.0 && tension_min == 0.0 && imap_max == 0.0 && imap_min == 0.0:
			var funny_array: Array = []
			funny_array.resize(fake_tension_map.map_grid[m].size())
			funny_array.fill(0.0)
			vulnerability_map.map_grid[m] = funny_array
			tension_map.map_grid[m] = funny_array
			vulnerability_map.update_row_value.emit(m, funny_array)
			tension_map.update_row_value.emit(m, funny_array)
			fake_tension_map.update_row_value.emit(m, funny_array)
			weighted_imap.update_row_value.emit(m, funny_array)
			continue
		
		var local_minimum_vuln_id: Vector2i = Vector2i.ZERO
		var local_vmap_extrema: float = 0.0
		var vmap_threshold: float = -0.5
		for n in range(0, vulnerability_map.width, 1):
			var imap_value: float = influence_map.map_grid[m][n]
			var weighted_imap_value: float = weighted_imap.map_grid[m][n]
			var tension_value: float = 0.0
			var vuln_value: float = 0.0
			if fake_tension_map.map_grid[m][n] == 0.0 and imap_value == 0.0:
				tension_map.map_grid[m][n] = tension_value
				vulnerability_map.map_grid[m][n] = vuln_value
				vulnerability_map.update_grid_value.emit(m, n, vuln_value)
				weighted_imap.update_grid_value.emit(m, n, weighted_imap_value)
				tension_map.update_grid_value.emit(m, n, tension_value)
				fake_tension_map.update_grid_value.emit(m, n, fake_tension_map.map_grid[m][n])
				continue
			
			tension_value = max(0, fake_tension_map.map_grid[m][n] - abs(imap_value))
			vuln_value = tension_value - abs(weighted_imap_value)
			tension_map.map_grid[m][n] = tension_value
			vulnerability_map.map_grid[m][n] = vuln_value
			if imap_value > 0.0:
				player_vulnerability[Vector2(m,n)] = vuln_value
			vulnerability_map.update_grid_value.emit(m, n, vuln_value)
			tension_map.update_grid_value.emit(m, n, tension_value)
			weighted_imap.update_grid_value.emit(m, n, weighted_imap_value)
			fake_tension_map.update_grid_value.emit(m, n, fake_tension_map.map_grid[m][n])
	
	if player_vulnerability.is_empty():
		agent.player_vulnerability = player_vulnerability
		return FAILURE
	
	var enemy_vuln_norm: Dictionary = {}
	var vuln_min: float = player_vulnerability.values().min()
	var vuln_max: float = player_vulnerability.values().max()
	for vuln_idx in player_vulnerability.keys():
		var value: float = player_vulnerability[vuln_idx]
		var norm_value: float = 2 * ((value - vuln_min) / (vuln_max - vuln_min)) - 1
		enemy_vuln_norm[vuln_idx] = norm_value
		#vulnerability_map.update_grid_value.emit(vuln_idx.x, vuln_idx.y, norm_value)
	
	var target_cells: Dictionary = {}
	var norm_max: float = enemy_vuln_norm.values().max()
	var norm_min: float = enemy_vuln_norm.values().min()
	for cell in enemy_vuln_norm:
		if enemy_vuln_norm[cell] == norm_max or enemy_vuln_norm[cell] == norm_min:
			target_cells[cell] = enemy_vuln_norm[cell]
	
	agent.player_vulnerability = target_cells
	return FAILURE
