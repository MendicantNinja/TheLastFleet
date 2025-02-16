extends LeafAction

var visited: Array = []

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 240 != 0:
		return FAILURE
	
	if agent.awaiting_orders.is_empty():
		return SUCCESS
	
	var isolated_targets: Array = agent.isolated_targets
	var vulnerable_targets: Dictionary = agent.vulnerable_targets
	
	var isolated_registry: Dictionary = {}
	for target: Ship in isolated_targets:
		isolated_registry[target.registry_cell] = target
	
	var await_order_back_idx: int = agent.awaiting_orders.size() - 1
	var current_group = agent.awaiting_orders[await_order_back_idx]
	var group_clusters: Array = []
	for unit: Ship in get_tree().get_nodes_in_group(current_group):
		if not group_clusters.has(unit.registry_cell):
			group_clusters.append(unit.registry_cell)
	
	var clusters_median: Vector2 = Vector2.ZERO
	if group_clusters.size() > 1:
		clusters_median = globals.geometric_median_of_objects(group_clusters)
	else:
		clusters_median = group_clusters[0]
	
	var target_cell: Vector2i = Vector2i.ZERO
	if agent.heuristic_strat == globals.Strategy.DEFENSIVE or agent.heuristic_strat == globals.Strategy.OFFENSIVE:
		var target_distances: Dictionary = {}
		for cell in isolated_registry:
			var distance_to: float = clusters_median.distance_squared_to(cell)
			target_distances[distance_to] = cell
		var min_distance: float = target_distances.keys().min()
		target_cell = target_distances[min_distance]
	elif agent.heuristic_strat == globals.Strategy.OFFENSIVE:
		pass # A lone island, trapped, distant from every landmass "worth living on"
		# According to someone who doesn't matter
	
	agent.queue_orders[agent.target_key] = [isolated_registry[target_cell]]
	
	return FAILURE
