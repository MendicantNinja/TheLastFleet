extends LeafAction

var strength_modifier: float = 1.0
var tmp_name: StringName = &"tmp"

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 240 != 0:
		return FAILURE
	
	var player_strength: float = agent.player_strength
	var admiral_strength: float = abs(agent.admiral_strength)
	var n_player_units: int = get_tree().get_node_count_in_group(&"friendly")
	var n_units: int = get_tree().get_node_count_in_group(&"enemy")
	var battle_agents: Array = get_tree().get_nodes_in_group(&"enemy")
	var available_units: Array = []
	var units_ranked: Dictionary = {}
	for unit: Ship in battle_agents:
		if unit == null:
			print("The destroyed unit %s still persists in memory in group_units.gd." % [unit.name])
			continue
		var floor_inf: float = floor(abs(unit.approx_influence))
		if unit.group_name.is_empty():
			available_units.append(unit)
			if not units_ranked.has(floor_inf):
				units_ranked[floor_inf] = []
			units_ranked[floor_inf].append(unit)
	
	if available_units.size() == 0:
		return SUCCESS
	
	if player_strength == 0 and admiral_strength == 0:
		return SUCCESS
	
	var relative_strength: float = admiral_strength / player_strength
	var unit_ratio: int = n_units / n_player_units
	if unit_ratio == 0:
		unit_ratio = 1
	
	var remainder: int = n_units % n_player_units
	var average_unit_strength: float = admiral_strength / n_units
	var strength_coefficient: float = strength_modifier
	var relative_group_size: int = n_units / unit_ratio
	if remainder > 1 and remainder != n_units:
		relative_group_size = (n_units - remainder) / unit_ratio
	elif remainder == n_units:
		relative_group_size = n_units
	strength_coefficient *= relative_group_size
	var adj_group_strength: float = average_unit_strength * strength_coefficient
	
	var sort_ranks: Array = units_ranked.keys()
	sort_ranks.sort()
	available_units = []
	for rank_idx in range(sort_ranks.size() - 1, -1, -1):
		var rank: float = sort_ranks[rank_idx]
		var file: Array = units_ranked[rank]
		for unit in file:
			available_units.append(unit)
	
	var visited_units: Array = []
	var main_group_count: int = relative_group_size * unit_ratio
	var previous_group: StringName = &""
	while visited_units.size() != main_group_count:
		var local_group: Array = []
		var group_strength: float = 0.0
		var group_positions: Dictionary = {}
		for unit in available_units:
			var unit_strength: float = round(abs(unit.approx_influence))
			if unit in visited_units:
				continue
			if group_strength < adj_group_strength and unit not in visited_units:
				unit.add_to_group(tmp_name)
				local_group.append(unit)
				visited_units.append(unit)
				group_positions[unit.global_position] = unit
				group_strength += unit_strength
			if group_strength >= adj_group_strength or local_group.size() == available_units.size():
				group_positions[unit.global_position] = unit
				unit.add_to_group(tmp_name)
				var group_name: StringName = agent.group_key_prefix + str(agent.iterator)
				get_tree().call_group(tmp_name, &"group_add", group_name)
				get_tree().call_group(group_name, &"group_remove", tmp_name)
				agent.available_groups.append(group_name)
				agent.awaiting_orders.append(group_name)
				break
			if visited_units.size() == available_units.size():
				break
		
		var new_leader: Ship = null
		if local_group.size() > 1:
			var median: Vector2 = globals.geometric_median_of_objects(group_positions.keys())
			new_leader = globals.find_unit_nearest_to_median(median, group_positions)
			new_leader.set_group_leader(true)
			group_strength = 0
			agent.iterator += 1
			previous_group = new_leader.group_name
		elif local_group.size() == 1:
			local_group[0].group_add(previous_group)
		
		if visited_units.size() == available_units.size():
				break
	
	if visited_units.size() == n_units:
		return FAILURE
	
	var group_name: StringName = agent.group_key_prefix + str(agent.iterator)
	for unit: Ship in available_units:
		if unit in visited_units:
			continue
		unit.add_to_group(tmp_name)
	agent.available_groups.append(group_name)
	agent.awaiting_orders.append(group_name)
	get_tree().call_group(tmp_name, &"group_add", group_name)
	get_tree().call_group(group_name, &"group_remove", tmp_name)
	# remainder stuff goes here
	return FAILURE
