extends LeafAction

# Main goal of this script is to make it so that units not currently engaged in combat
# determine if an incoming threat is worth attacking or falling back to a better position.
var tru_name: StringName = &""
var tmp_name: StringName = &"threat detect "

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 65 != 0 or agent.registry_cell == -Vector2i.ONE:
		return FAILURE
	elif agent.target_unit != null or agent.targeted_units.is_empty() == false:
		return FAILURE
	elif agent.vent_flux_flag == true or agent.fallback_flag == true or agent.retreat_flag == true:
		return FAILURE
	
	if tru_name.is_empty() and agent.is_friendly == true:
		tru_name = &"Temporary Friendly Group "
		tmp_name += &"friendly"
	elif tru_name.is_empty() and agent.is_friendly == false:
		tru_name = &"Temporary Enemy Group "
		tmp_name += &"enemy"
	
	var attacker_groups: Array = []
	var neighbor_units: Array = []
	var neighbor_groups: Array = []
	for cell in agent.registry_neighborhood:
		if not imap_manager.registry_map.has(cell):
			continue
		var registered_units: Array = imap_manager.registry_map[cell]
		for unit in registered_units:
			if unit.is_friendly == agent.is_friendly and unit.group_name.is_empty():
				neighbor_units.append(unit)
			elif unit.is_friendly == agent.is_friendly and not unit.group_name in neighbor_groups:
				neighbor_groups.append(unit.group_name)
			elif unit in agent.targeted_by and not unit.group_name in attacker_groups:
				attacker_groups.append(unit.group_name)
	
	if attacker_groups.is_empty():
		return FAILURE
	
	if agent.group_name.is_empty() and neighbor_groups.is_empty() and neighbor_units.is_empty() == false:
		var unit_positions: Dictionary = {}
		for unit in neighbor_units:
			unit.add_to_group(tmp_name)
			unit_positions[unit.global_position] = unit
		var geo_median: Vector2 = globals.geometric_median_of_objects(unit_positions.keys())
		var leader: Ship = globals.find_unit_nearest_to_median(geo_median, unit_positions)
		var new_group_name: StringName = tru_name + agent.name
		get_tree().call_group(tmp_name, &"group_add", new_group_name)
		leader.set_group_leader(true)
	
	if agent.group_name.is_empty() and neighbor_groups.is_empty() == false:
		var pick_rand_group: int = randi_range(0, neighbor_groups.size() - 1)
		var rand_group_member: Ship = get_tree().get_first_node_in_group(neighbor_groups[pick_rand_group])
		agent.targeted_units = rand_group_member.targeted_units
		agent.group_add(neighbor_groups[pick_rand_group])
	
	if agent.group_name.is_empty():
		return FAILURE
	
	var group_strength: float = 0.0
	for unit in get_tree().get_nodes_in_group(agent.group_name):
		if unit.combat_flag == true:
			return FAILURE
		group_strength += unit.approx_influence
	
	var attackers: Array = []
	var total_attacker_strength: float = 0.0
	for group_name in attacker_groups:
		var relative_strength: float = 0.0
		for unit in get_tree().get_nodes_in_group(group_name):
			if unit == null or unit in agent.targeted_units:
				continue
			attackers.append(unit)
			relative_strength += unit.approx_influence
		total_attacker_strength += relative_strength
	
	if attackers.is_empty():
		return FAILURE
	
	if agent.is_friendly == true:
		pass
	
	var relative_strength: float = abs(group_strength / total_attacker_strength)
	if relative_strength >= 1.0:
		get_tree().call_group(agent.group_name, &"set_targets", attackers)
	else:
		pass
		#get_tree().call_group(agent.group_name, &"set_fallback_flag", true)
	
	return FAILURE
