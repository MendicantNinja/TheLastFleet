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

var snap_target: float = 0.1
var n_initial_enemy: int = 0
var n_initial_allies: int = 0

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if n_initial_enemy == 0:
		if agent.is_friendly == true:
			n_initial_enemy = get_tree().get_node_count_in_group(&"enemy")
			n_initial_allies = get_tree().get_node_count_in_group(&"friendly")
		else:
			n_initial_enemy = get_tree().get_node_count_in_group(&"friendly")
			n_initial_allies = get_tree().get_node_count_in_group(&"enemy")
		
	if Engine.get_physics_frames() % 67 != 0:
		return FAILURE
	
	if agent.fallback_flag == true or agent.retreat_flag == true or agent.vent_flux_flag == true:
		return FAILURE
	
	if agent.targeted_units.is_empty():
		return FAILURE
	
	if agent.target_unit != null:
		return FAILURE
	
	var weigh_targets: Dictionary = {}
	var evaluate_targets: Array = []
	var available_targets: Array = []
	var sq_dist: Array = []
	#var target_dist: Dictionary = {}
	for target in agent.targeted_units:
		if target == null:
			continue
		var prob: float = agent.generate_combat_probability(target)
		if not weigh_targets.has(prob):
			weigh_targets[prob] = []
		weigh_targets[prob].append(target.get_rid())
		
		var dist: float = agent.global_position.distance_squared_to(target.global_position)
		sq_dist.append(dist)
		#target_dist[dist] = target
		if target.targeted_by.is_empty() == false:
			evaluate_targets.append(target)
		else:
			available_targets.append(target)
	
	for weapon in agent.all_weapons:
		weapon.weighted_targets = weigh_targets
	
	if evaluate_targets.is_empty() and available_targets.is_empty():
		return FAILURE
	
	var min_dist: float = sq_dist.min()
	
	for target in evaluate_targets:
		var target_weapons: int = target.all_weapons.size()
		var final_weighted_prob: float = 0.0
		for attacker in target.targeted_by:
			if attacker == null:
				continue
			if attacker == agent and agent.target_unit == null:
				agent.target_unit = target
				return FAILURE
			var agent_inf: float = abs(attacker.approx_influence)
			var target_inf: float = abs(target.approx_influence)
			var threat_weight: float = agent_inf / (agent_inf + target_inf)
			var flux_weight: float = (target.soft_flux + target.hard_flux) / target.total_flux
			var weapon_weight: float = target_weapons / attacker.all_weapons.size()
			var dist_weight: float = min_dist / agent.global_position.distance_squared_to(target.global_position)
			final_weighted_prob += (threat_weight + flux_weight + dist_weight + weapon_weight) / 4.0
		if final_weighted_prob < 1.0:
			available_targets.append(target)
	
	if available_targets.is_empty():
		return FAILURE
	
	var agent_weapons: int = agent.all_weapons.size()
	var weighted_targets: Dictionary = {}
	for target: Ship in available_targets:
		var agent_inf: float = abs(agent.approx_influence)
		var target_inf: float = abs(target.approx_influence)
		var threat_weight: float = agent_inf / (agent_inf + target_inf)
		var flux_weight: float = (target.soft_flux + target.hard_flux) / target.total_flux
		var weapon_weight: float = agent_weapons / target.all_weapons.size()
		var dist_weight: float = min_dist / agent.global_position.distance_squared_to(target.global_position)
		var prob: float = (threat_weight + flux_weight + dist_weight + weapon_weight) / 4.0
		if snappedf(prob, snap_target) < 0.5:
			continue
		weighted_targets[prob] = target
	
	var target: Ship = null
	if weighted_targets.is_empty():
		var rand_target: int = randi_range(0, available_targets.size() - 1)
		target = available_targets[rand_target]
		#print("%s randomly choose %s to target" % [agent.name, target.name])
	else:
		var max_prob: float = weighted_targets.keys().max()
		target = weighted_targets[max_prob]
		#print("%s targeting %s with %1.3f probability of winning" % [agent.name, target.name, max_prob])
	agent.target_unit = target
	target.targeted_by.append(agent)
	agent.set_target_for_weapons(target)
	return FAILURE
