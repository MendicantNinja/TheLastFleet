extends LeafAction

var groups_initialized: bool = false

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if groups_initialized == true:
		return SUCCESS
	
	var friendly_units_size: int = get_tree().get_node_count_in_group(&"friendly")
	var available_units_size: int = agent.available_units.size()
	var au_remainder: int = available_units_size % friendly_units_size
	var gen_group_size: int = 0
	if friendly_units_size == available_units_size:
		gen_group_size = available_units_size
	elif au_remainder == 0: # friendly unit size > available unit size and proper divisor
		gen_group_size = available_units_size / friendly_units_size
	elif au_remainder == available_units_size: # friendly unit size > available unit size
		gen_group_size = available_units_size
	else: # friendly unit size < available unit size
		gen_group_size = (friendly_units_size - au_remainder) / friendly_units_size
	
	var unit_counter: int = 0
	var group_name: StringName = agent.enemy_group_key_prefix + str(agent.iterator)
	var unit_positions: Dictionary = {}
	for unit in agent.available_units:
		unit_counter += 1
		unit.add_to_group(group_name)
		unit.group_name = group_name
		unit.destroyed.connect(agent._on_unit_destroyed.bind(unit, group_name))
		unit_positions[unit.global_position] = unit
		if unit_counter == gen_group_size:
			var median: Vector2 = globals.geometric_median_of_objects(unit_positions)
			var leader = globals.find_unit_nearest_to_median(median, unit_positions)
			leader.set_group_leader(true)
			leader.destroyed.disconnect(agent._on_unit_destroyed)
			leader.destroyed.connect(agent._on_leader_destroyed.bind(leader, group_name))
			agent.group_leaders[group_name] = leader
			agent.available_groups[group_name] = get_tree().get_nodes_in_group(group_name)
			agent.order_groups.push_back(group_name)
			unit_positions = {}
			unit_counter = 0
			agent.iterator += 1
			group_name = agent.enemy_group_key_prefix + str(agent.iterator)
		
	
	groups_initialized = true
	return SUCCESS
