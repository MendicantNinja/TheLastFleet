extends LeafAction

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 120 != 0:
		return FAILURE
	
	agent.match_velocity_flag = false
	
	if agent.posture == globals.Strategy.OFFENSIVE or agent.posture == globals.Strategy.EVASIVE:
		return FAILURE
	elif agent.group_name.is_empty() == true:
		return FAILURE
	
	if agent.combat_flag == false and agent.fallback_flag == false and agent.retreat_flag == false and agent.vent_flux_flag == false:
		agent.match_velocity_flag = true
	
	for unit in get_tree().get_nodes_in_group(agent.group_name):
		if unit == null:
			continue
		if unit.combat_flag == true:
			agent.match_velocity_flag = false
			break
	
	if agent.match_velocity_flag == false:
		return FAILURE
	
	var speed: Array = []
	for unit in get_tree().get_nodes_in_group(agent.group_name):
		if unit == null:
			continue
		speed.append(unit.speed)
	
	var velocity: float = agent.heur_velocity.length()
	var min_velocity: float = speed.min()
	agent.match_speed = min_velocity
	
	return FAILURE
