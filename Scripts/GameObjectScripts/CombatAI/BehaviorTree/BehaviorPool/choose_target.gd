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
	if agent.target_unit != null or agent.fallback_flag == true or agent.retreat_flag == true or agent.vent_flux_flag == true:
		return SUCCESS
	
	if agent.targeted_units.is_empty():
		return SUCCESS
	
	var available_targets: Array = []
	var sq_dist: Array = []
	var target_dist: Dictionary = {}
	for target in agent.targeted_units:
		var dist: float = agent.global_position.distance_squared_to(target.global_position)
		sq_dist.append(dist)
		target_dist[dist] = target
		if target.retreat_flag == true:
			continue
		available_targets.append(target)
	
	if available_targets.is_empty():
		agent.target_unit = target_dist[target_dist.keys().min()]
		return SUCCESS
	
	var min_dist: float = sq_dist.min()
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
	#print("%s targeting %s with %1.3f probability of winning" % [agent.name, weighted_targets[max_prob].name, max_prob])
	weighted_targets[max_prob].targeted_by.append(agent)
	agent.targeted_units = available_targets
	agent.set_target_for_weapons(weighted_targets[max_prob])
	return SUCCESS
