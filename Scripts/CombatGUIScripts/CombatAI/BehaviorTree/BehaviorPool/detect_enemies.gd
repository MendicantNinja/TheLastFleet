extends LeafAction

var clusters: Array = []
var visited: Array = []

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 120 != 0:
		return FAILURE
	
	var registry_cells: Dictionary = imap_manager.registry_map
	var enemy_presence: Array = []
	for cell in registry_cells.keys():
		var registered_agents: Array = registry_cells[cell]
		for n_agent in registered_agents:
			if n_agent == null:
				continue
			if n_agent.is_friendly == true:
				enemy_presence.push_back(cell)
				break
	
	if enemy_presence.is_empty():
		return SUCCESS
	
	for cell in enemy_presence:
		if cell not in visited:
			var cluster = []
			clusters.append(flood_fill(cell, visited, cluster, enemy_presence))
	
	agent.enemy_clusters = clusters
	clusters = []
	visited = []
	return FAILURE

func flood_fill(cell, visited, cluster, enemy_presence) -> Array: 
	if cell in visited: 
		return cluster
	 
	visited.append(cell) 
	cluster.append(cell) 
	for n_cell in enemy_presence: 
		if cell.distance_squared_to(n_cell) == 1: 
			flood_fill(n_cell, visited, cluster, enemy_presence)
	return cluster
