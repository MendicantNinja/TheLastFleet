extends LeafAction

var strength_modifier: float = 1.0
var tmp_name: StringName = &"tmp"

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 240 != 0:
		return FAILURE
	
	var player_total_strength: float = 0.0
	var admiral_total_strength: float = 0.0
	var available_player_units: int = 0
	var available_enemy_units: int = 0
	var battle_agents: Array = get_tree().get_nodes_in_group(&"agent")
	var available_units: Array = []
	var units_ranked: Dictionary = {}
	for unit: Ship in battle_agents:
		if unit == null:
			print("The destroyed unit %s still persists in memory in group_units.gd." % [unit.name])
			continue
		var floor_inf: float = floor(abs(unit.approx_influence))
		if unit.is_friendly == true:
			player_total_strength += floor_inf
			available_player_units += 1
		else:
			admiral_total_strength += floor_inf
			available_enemy_units += 1
		
		if unit.is_friendly == false and unit.group_name.is_empty():
			available_units.append(unit)
			if not units_ranked.has(floor_inf):
				units_ranked[floor_inf] = []
			units_ranked[floor_inf].append(unit)
	
	if available_units.size() == 0:
		return FAILURE
	
	var relative_strength: float = admiral_total_strength / player_total_strength
	var unit_ratio: int = available_enemy_units / available_player_units
	if unit_ratio == 0:
		unit_ratio = 1
	
	var remainder: int = available_enemy_units % available_player_units
	var average_unit_strength: float = admiral_total_strength / available_enemy_units
	var strength_coefficient: float = strength_modifier
	var base_group_strength: float = relative_strength * average_unit_strength
	var relative_group_size: int = available_enemy_units / unit_ratio
	if remainder > 1 and remainder != available_enemy_units:
		relative_group_size = (available_enemy_units - remainder) / unit_ratio
		strength_coefficient *= relative_group_size
	var adj_group_strength: float = base_group_strength * strength_coefficient
	
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
	while visited_units.size() != main_group_count:
		var local_group_ranks: Dictionary = {}
		var local_group: Array = []
		for unit in available_units:
			if unit in visited_units:
				continue
			var rank: float = floor(abs(unit.approx_influence))
			if not local_group_ranks.has(rank):
				local_group_ranks[rank] = []
			var file_size: float = (units_ranked[rank].size() - remainder) / unit_ratio
			if remainder == 0 or file_size <= 0:
				file_size = available_enemy_units / unit_ratio
			var rank_str_total: float = rank * units_ranked[rank].size() 
			var adj_rank_strength: float = adj_group_strength / rank_str_total
			var unit_allocation: int = round(file_size * adj_rank_strength)
			if unit_allocation <= 0:
				unit_allocation = 1
			if local_group_ranks[rank].size() != unit_allocation and unit not in visited_units:
				unit.group_add(tmp_name)
				local_group.append(unit)
				visited_units.append(unit)
				local_group_ranks[rank].append(unit)
			if local_group.size() == relative_group_size or local_group.size() == available_units.size():
				var group_name: StringName = agent.group_key_prefix + str(agent.iterator)
				get_tree().call_group(tmp_name, &"group_add", group_name)
				get_tree().call_group(group_name, &"group_remove", tmp_name)
				break
		agent.iterator += 1
	
	# remainder stuff goes here
	return FAILURE
