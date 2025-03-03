extends LeafAction

# choose_target: Selects the best target for the unit based on distance, threat level, and health.
# Assumptions:
# 1. Actions preceding this action would prevent the unit from entering combat.
# 2. Relevant environmental information is available to the unit. 
# Assessments:
# 1. If the unit is still alive.
# 2. If more than one unit is already targetting one of the available targets.
# 3. If the unit is currently retreating from combat.
# 4. Weighing targeted units
#	a. Distance
#		-> Further away trends to zero
#	b. Threat 
#		-> Use approx influence
#	c. Health
#		-> Flux is priority
#	-> Future iterations will weigh other environmental factors with a working map.
# Notes:
#	- Each units approx influence is reweighed in the variable "weigh influence"
#		- Maybe useful as a modifier/coefficient

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.fallback_flag == true or agent.retreat_flag == true or agent.vent_flux_flag == true:
		return FAILURE
	
	if agent.targeted_units.is_empty():
		return FAILURE
	
	if agent.target_unit != null and Engine.get_physics_frames() % 500 != 0:
		return FAILURE
	
	var evaluate_targets: Array = []
	var available_targets: Array = []
	var sq_dist: Array = []
	var target_dist: Dictionary = {}
	for target in agent.targeted_units:
		if target == null:
			continue
		var dist: float = agent.global_position.distance_squared_to(target.global_position)
		sq_dist.append(dist)
		target_dist[dist] = target
		if target.retreat_flag == true:
			continue
		if target.targeted_by.is_empty() == false:
			evaluate_targets.append(target)
		else:
			available_targets.append(target)
	
	if evaluate_targets.is_empty() and available_targets.is_empty():
		return FAILURE
	
	var min_dist: float = sq_dist.min()
	for target in evaluate_targets:
		var final_weighted_prob: float = 0.0
		for attacker in target.targeted_by:
			if attacker == null:
				continue
			var agent_inf: float = abs(attacker.approx_influence)
			var target_inf: float = abs(target.approx_influence)
			var threat_weight: float = agent_inf / (agent_inf + target_inf)
			var flux_weight: float = (target.soft_flux + target.hard_flux) / target.total_flux
			var dist_weight: float = min_dist / agent.global_position.distance_squared_to(target.global_position)
			final_weighted_prob += (threat_weight + flux_weight + dist_weight) / 3.0
		if final_weighted_prob < 1.0:
			available_targets.append(target)
	
	if available_targets.is_empty():
		return FAILURE
	
	var weighted_targets: Dictionary = {}
	for target: Ship in available_targets:
		var agent_inf: float = abs(agent.approx_influence)
		var target_inf: float = abs(target.approx_influence)
		var threat_weight: float = agent_inf / (agent_inf + target_inf)
		var flux_weight: float = (target.soft_flux + target.hard_flux) / target.total_flux
		var dist_weight: float = min_dist / agent.global_position.distance_squared_to(target.global_position)
		var prob: float = (threat_weight + flux_weight + dist_weight) / 3.0
		weighted_targets[prob] = target
	
	var max_prob: float = weighted_targets.keys().max()
	agent.target_unit = weighted_targets[max_prob]
	print("%s targeting %s with %1.3f probability of winning" % [agent.name, weighted_targets[max_prob].name, max_prob])
	weighted_targets[max_prob].targeted_by.append(agent)
	agent.set_target_for_weapons(weighted_targets[max_prob])
	return FAILURE
