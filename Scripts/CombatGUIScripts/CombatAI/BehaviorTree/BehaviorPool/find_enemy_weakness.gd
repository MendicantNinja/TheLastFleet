extends LeafAction

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 180 != 0:
		return FAILURE
		
	var influence_map: Imap = imap_manager.current_maps[imap_manager.MapType.INFLUENCE_MAP]
	var fake_tension_map: Imap = imap_manager.current_maps[imap_manager.MapType.TENSION_MAP]
	var tension_map: Imap = imap_manager.tension_map
	var vulnerability_map: Imap = imap_manager.vulnerability_map
	var enemy_influence_extrema: Dictionary = {}
	var enemy_vuln_extrema: Dictionary = {}
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
			continue
		
		var local_maximum_imap_id: Vector2i = Vector2i.ZERO
		var local_maximum_imap: float = 0.0
		var imap_threshold: float = 0.5
		var local_minimum_vuln_id: Vector2i = Vector2i.ZERO
		var local_minimum_vmap: float = 0.0
		var vmap_threshold: float = -0.5
		for n in range(0, vulnerability_map.width, 1):
			var imap_value: float = influence_map.map_grid[m][n]
			var tension_value: float = 0.0
			var vuln_value: float = 0.0
			if imap_value == 0.0 and local_maximum_imap > 0.0:
				enemy_influence_extrema[local_maximum_imap_id] = local_maximum_imap
				local_maximum_imap = 0.0
			if fake_tension_map.map_grid[m][n] == 0.0 and imap_value == 0.0:
				tension_map.map_grid[m][n] = tension_value
				tension_map.update_grid_value.emit(m, n, tension_value)
				vulnerability_map.map_grid[m][n] = vuln_value
				vulnerability_map.update_grid_value.emit(m, n, vuln_value)
				continue
			if imap_value > 0.0 and imap_value > imap_threshold and imap_value > local_maximum_imap:
				local_maximum_imap = imap_value
				local_maximum_imap_id = Vector2i(m, n)
			tension_value = max(0, fake_tension_map.map_grid[m][n] - abs(imap_value))
			vuln_value = tension_value - abs(imap_value)
			tension_map.map_grid[m][n] = tension_value
			vulnerability_map.map_grid[m][n] = vuln_value
			if vuln_value > local_minimum_vmap and vuln_value < vmap_threshold:
				enemy_vuln_extrema[local_minimum_vuln_id] = local_minimum_vmap
				local_minimum_vmap = 0.0
			elif imap_value > 0.0 and vuln_value < local_minimum_vmap and vuln_value < vmap_threshold:
				local_minimum_vmap = vuln_value
				local_minimum_vuln_id = Vector2i(m,n)
			
			tension_map.update_grid_value.emit(m, n, tension_value)
	
	var vuln_min: float = enemy_vuln_extrema.values().min()
	var vuln_max: float = enemy_vuln_extrema.values().max()
	var enemy_vuln_norm: Dictionary = {}
	for vuln_idx in enemy_vuln_extrema.keys():
		var value: float = enemy_vuln_extrema[vuln_idx]
		var norm_value: float = 2 * ((value - vuln_min) / (vuln_max - vuln_min)) - 1
		enemy_vuln_norm[vuln_idx] = norm_value
		vulnerability_map.update_grid_value.emit(vuln_idx.x, vuln_idx.y, norm_value)
	
	var target_cell_ids: Dictionary = {}
	var norm_max: float = enemy_vuln_norm.values().max()
	for cell_idx in enemy_vuln_norm:
		if enemy_vuln_norm[cell_idx] == norm_max:
			target_cell_ids[cell_idx] = Vector2(cell_idx.y * imap_manager.default_cell_size, cell_idx.x * imap_manager.default_cell_size)
	
	var enemy_clusters: Array = agent.enemy_clusters
	for cluster in enemy_clusters:
		pass
	#var agent_registry: Dictionary = imap_manager.agent_registry
	#var enemy_group: Array = get_tree().get_nodes_in_group(&"friendly")
	#var target_units: Array = []
	#for cell_idx in target_cell_ids:
		#var agent_distances: Dictionary = {}
		#var cell_pos: Vector2 = Vector2(cell_idx.y * imap_manager.default_cell_size, cell_idx.x * imap_manager.default_cell_size)
		#for enemy in enemy_group:
			#var distance_to: float = cell_pos.distance_squared_to(enemy.global_position)
			#agent_distances[distance_to] = enemy
		#var min_distance = agent_distances.keys().min()
		#if not target_units.has(agent_distances[min_distance]):
			#target_units.push_back(agent_distances[min_distance])
	
	return FAILURE
