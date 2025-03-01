extends LeafAction

# The unit is in combat and assessing whether or not to fallback or set a new target
func tick(agent: Ship, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 65 != 0 or agent.combat_flag == false:
		return FAILURE
	
	var targeted_by: Array = []
	var enemy_group: Array = []
	for unit in targeted_by:
		if unit in agent.targeted_units or unit == agent.target_unit:
			continue
		targeted_by.append(unit)
	
	
	return FAILURE
