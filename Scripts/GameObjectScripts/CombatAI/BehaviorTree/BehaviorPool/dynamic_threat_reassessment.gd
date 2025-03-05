extends LeafAction

# The unit is in combat and assessing whether or not to fallback or set a new target
func tick(agent: Ship, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 120 != 0 or agent.target_position != Vector2.ZERO or agent.combat_flag == false or agent.fallback_flag == true or agent.retreat_flag == true:
		return FAILURE
	
	var enemy_group: Array = agent.nearby_attackers
	var target_units: Array = []
	var total_attacker_strength: float = 0.0
	for group_name in agent.nearby_attackers:
		var group: Array = get_tree().get_nodes_in_group(group_name)
		for unit in group:
			if unit == null:
				continue
			target_units.append(unit)
			total_attacker_strength += unit.approx_influence
	
	var current_target_strength: float = 0.0
	for unit in agent.targeted_units:
		if unit == null:
			continue
		current_target_strength += unit.approx_influence
	
	var current_group_strength: float = 0.0
	for unit in get_tree().get_nodes_in_group(agent.group_name):
		if unit == null:
			continue
		current_group_strength += unit.approx_influence
		target_units.append(unit)
	
	if target_units.is_empty():
		return FAILURE
	
	var combined_enemy_strength: float = total_attacker_strength + current_target_strength
	var relative_strength: float = abs(current_group_strength / combined_enemy_strength)
	if relative_strength >= 1.0:
		get_tree().call_group(agent.group_name, &"set_targets", target_units)
	#else:
		#get_tree().call_group(agent.group_name, &"set_fallback_flag", true)
	
	return FAILURE
