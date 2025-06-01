extends LeafAction

# Main goal of this script is to make it so that units not currently engaged in combat
# determine if an incoming threat is worth attacking or falling back to a better position.
var tru_name: StringName = &""
var tmp_name: StringName = &"threat detect "

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 120 != 0 or agent.registry_cell == -Vector2i.ONE or agent.target_position != Vector2.ZERO:
		return FAILURE
	elif agent.combat_flag == true or agent.vent_flux_flag == true or agent.fallback_flag == true or agent.retreat_flag == true:
		return FAILURE
	
	if tru_name.is_empty() and agent.is_friendly == true:
		tru_name = &"Temporary Friendly Group "
		tmp_name += &"tmp friendly"
	elif tru_name.is_empty() and agent.is_friendly == false:
		tru_name = &"Temporary Enemy Group "
		tmp_name += &"tmp enemy"
	
	for unit in get_tree().get_nodes_in_group(agent.group_name):
		if unit == null:
			continue
		if unit.target_position != Vector2.ZERO or agent.combat_flag == true:
			return FAILURE
	
	var attacker_groups: Array = agent.nearby_attackers
	if attacker_groups.is_empty():
		return FAILURE
	
	var idle_neighbors: Array = agent.idle_neighbors
	var available_neighbor_groups: Array = agent.available_neighbor_groups
	
	if agent.group_name.is_empty() == true and available_neighbor_groups.is_empty() and idle_neighbors.is_empty() == false:
		var unit_positions: Dictionary = {}
		for unit in idle_neighbors:
			unit.add_to_group(tmp_name)
			unit_positions[unit.global_position] = unit
		var geo_median: Vector2 = globals.geometric_median_of_objects(unit_positions.keys())
		var leader: Ship = globals.find_unit_nearest_to_median(geo_median, unit_positions)
		var new_group_name: StringName = tru_name + agent.name
		get_tree().call_group(tmp_name, &"group_add", new_group_name)
		get_tree().call_group(tmp_name, &"group_remove", tmp_name)
		leader.set_group_leader(true)
	
	if agent.group_name.is_empty() == true and available_neighbor_groups.is_empty() == false:
		var pick_rand_group: int = randi_range(0, available_neighbor_groups.size() - 1)
		var group_name: StringName = available_neighbor_groups[pick_rand_group]
		var rand_group_member: Ship = get_tree().get_first_node_in_group(group_name)
		agent.targeted_units = rand_group_member.targeted_units
		agent.group_add(available_neighbor_groups[pick_rand_group])
	
	if agent.group_name.is_empty():
		return FAILURE
	
	var agent_group_strength: float = 0.0
	for unit in get_tree().get_nodes_in_group(agent.group_name):
		if unit == null:
			continue
		agent_group_strength += unit.approx_influence
	
	var attackers: Array = []
	var total_attacker_strength: float = 0.0
	for group_name in attacker_groups:
		var relative_strength: float = 0.0
		for unit in get_tree().get_nodes_in_group(group_name):
			if unit == null:
				continue
			attackers.append(unit)
			relative_strength += unit.approx_influence
		total_attacker_strength += relative_strength
	
	if attackers.is_empty():
		return FAILURE
	
	var nearby_group_strength: Dictionary = {}
	for group_name in available_neighbor_groups:
		var relative_group_strength: float = 0.0
		for unit in get_tree().get_nodes_in_group(group_name):
			if unit == null:
				continue
			relative_group_strength += unit.approx_influence
		if relative_group_strength == 0.0:
			continue
		nearby_group_strength[relative_group_strength + agent_group_strength] = group_name
	
	var relative_strength: float = abs(agent_group_strength / total_attacker_strength)
	if relative_strength >= 1.0:
		get_tree().call_group(agent.group_name, &"set_targets", attackers)
		return FAILURE
	
	for strength in nearby_group_strength:
		var group_name: StringName = nearby_group_strength[strength]
		relative_strength = abs(strength / total_attacker_strength)
		if relative_strength >= 1.0:
			get_tree().call_group(group_name, &"group_add", agent.group_name)
			if group_name != agent.group_name:
				get_tree().call_group(group_name, &"group_remove", group_name)
			get_tree().call_group(agent.group_name, &"set_targets", attackers)
			return FAILURE
	
	#get_tree().call_group(agent.group_name, &"set_fallback_flag", true)
	return FAILURE
