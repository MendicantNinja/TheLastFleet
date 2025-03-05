extends LeafAction

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 120 != 0:
		return FAILURE
	
	var nearby_enemy_groups: Array = []
	var idle_neighbors: Array = []
	var neighbor_groups: Array = []
	for cell in agent.registry_neighborhood:
		if not imap_manager.registry_map.has(cell):
			continue
		for unit in imap_manager.registry_map[cell]:
			if unit == null:
				continue
			if unit.group_name == agent.group_name and unit.group_name.is_empty() == false and agent.group_name.is_empty() == false:
				continue
			if unit.is_friendly == agent.is_friendly and unit.group_name.is_empty():
				idle_neighbors.append(unit)
			if unit.is_friendly != agent.is_friendly and unit.group_name.is_empty() == false and not unit.group_name in nearby_enemy_groups:
				nearby_enemy_groups.append(unit.group_name)
			if unit.is_friendly == agent.is_friendly and unit.group_name.is_empty() == false and not unit.group_name in neighbor_groups:
				neighbor_groups.append(unit.group_name)
	
	var nearby_attackers: Array = []
	for unit in agent.targeted_by:
		if unit == null:
			continue
		if not unit.group_name in nearby_attackers:
			nearby_attackers.append(unit.group_name)
	
	for unit in get_tree().get_nodes_in_group(agent.group_name):
		if unit == null:
			continue
		for attacker in unit.targeted_by:
			if attacker == null:
				continue
			if not attacker.group_name in nearby_attackers:
				nearby_attackers.append(attacker.group_name)
	
	var available_neighbor_groups: Array = []
	for group_name in neighbor_groups:
		var availability_count: int = 0
		var group: Array = get_tree().get_nodes_in_group(group_name)
		for unit in get_tree().get_nodes_in_group(group_name):
			if unit == null:
				continue
			if unit.targeted_units.is_empty() == true and unit.target_position == Vector2.ZERO and agent.combat_flag == false:
				availability_count += 1
		if availability_count == group.size():
			available_neighbor_groups.append(group_name)
	
	agent.available_neighbor_groups = available_neighbor_groups
	agent.nearby_enemy_groups = nearby_enemy_groups
	agent.idle_neighbors = idle_neighbors
	agent.neighbor_groups = neighbor_groups
	agent.nearby_attackers = nearby_attackers
	return FAILURE
