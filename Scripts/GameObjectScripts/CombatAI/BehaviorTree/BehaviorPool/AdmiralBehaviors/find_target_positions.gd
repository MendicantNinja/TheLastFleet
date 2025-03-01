extends LeafAction

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if agent.heuristic_goal != globals.GOAL.SKIRMISH:
		return FAILURE
	
	if Engine.get_physics_frames() % 240 != 0:
		return FAILURE
	
	var goal_positions: Array = []
	var player_vulnerability: Dictionary = {}
	var goal_cells: Array = []
	if not agent.control_points.is_empty():
		goal_positions = agent.control_points
		return SUCCESS
	elif not agent.player_vulnerability.is_empty():
		player_vulnerability = agent.player_vulnerability
		goal_positions = player_vulnerability.keys()
	
	var vulnerable_positions: Array = []
	var isolated_targets: Array = []
	for cell in player_vulnerability:
		var value: int = player_vulnerability[cell]
		if value > 0:
			vulnerable_positions.append(cell)
		elif value < 0:
			isolated_targets.append(cell)
	
	agent.vulnerable_cells = vulnerable_positions
	agent.isolated_cells = isolated_targets
	
	var friendly_cluster: Array = imap_manager.friendly_cluster
	
	var iso_cluster: Dictionary = {}
	for cell in isolated_targets:
		var position: Vector2 = Vector2(cell.y * imap_manager.default_cell_size, cell.x * imap_manager.default_cell_size)
		var registry_cell: Vector2i = Vector2i(position.y / imap_manager.max_cell_size, position.x / imap_manager.max_cell_size)
		for cluster in friendly_cluster:
			if registry_cell in cluster and cluster not in iso_cluster:
				iso_cluster[cluster] = []
			if registry_cell in cluster:
				iso_cluster[cluster].append(cell)
	
	var vuln_cluster: Dictionary = {}
	for cell in vulnerable_positions:
		var position: Vector2 = Vector2(cell.y * imap_manager.default_cell_size, cell.x * imap_manager.default_cell_size)
		var registry_cell: Vector2i = Vector2i(position.y / imap_manager.max_cell_size, position.x / imap_manager.max_cell_size)
		for cluster in friendly_cluster:
			if registry_cell in cluster and cluster not in vuln_cluster:
				vuln_cluster[cluster] = []
			if registry_cell in cluster:
				vuln_cluster[cluster].append(cell)
	if vuln_cluster.is_empty() and iso_cluster.is_empty():
		return FAILURE
	
	var funny_med_cells: Array = []
	var iso_cluster_geo_med: Dictionary = {}
	var remove_iso_cluster: Array = []
	for cluster in iso_cluster:
		if cluster in vuln_cluster.keys():
			remove_iso_cluster.append(cluster)
			continue
		var cells: Array = iso_cluster[cluster]
		var geo_med: Vector2 = globals.geometric_median_of_objects(cells)
		iso_cluster_geo_med[cluster] = Vector2i(geo_med.x, geo_med.y)
		funny_med_cells.append(Vector2i(geo_med.x, geo_med.y))
	
	for cluster in remove_iso_cluster: 
		iso_cluster.erase(cluster)
	
	var vuln_cluster_geo_med: Dictionary = {}
	for cluster in vuln_cluster:
		var cells: Array = vuln_cluster[cluster]
		var geo_med: Vector2 = globals.geometric_median_of_objects(cells)
		vuln_cluster_geo_med[cluster] = Vector2i(geo_med.x, geo_med.y)
		funny_med_cells.append(Vector2i(geo_med.x, geo_med.y))
	
	var dist_to_geo_med: Dictionary = {}
	for cell in funny_med_cells:
		var baseline: Vector2i = Vector2i.ZERO
		var dist_to: float = cell.distance_squared_to(baseline)
		dist_to_geo_med[dist_to] = cell
	
	var furthest_cell: Vector2i = dist_to_geo_med[dist_to_geo_med.keys().max()]
	var goal_radius: int = Vector2i.ZERO.distance_to(furthest_cell) / 2
	agent.goal_radius = goal_radius
	for gm_cell in iso_cluster_geo_med:
		var goal_cell: Vector2i = iso_cluster_geo_med[gm_cell]
		agent.goal_value[goal_cell] = 1.0
	
	for gm_cell in vuln_cluster_geo_med:
		var goal_cell: Vector2i = vuln_cluster_geo_med[gm_cell]
		if iso_cluster.is_empty():
			agent.goal_value[goal_cell] = 1.0
		else:
			agent.goal_value[goal_cell] = -1.0
	
	return SUCCESS
