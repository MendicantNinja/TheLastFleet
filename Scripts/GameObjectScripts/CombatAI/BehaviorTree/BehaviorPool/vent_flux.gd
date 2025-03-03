extends LeafAction

var total_flux: float = 0.0
var safe_distance: float = 0.0
var offensive_threshold: float = 0.9
var def_neut_threshold: float = 0.7
var evasive_threshold: float = 0.5
var default_radius: int = 10
var delta: float = 0.0
var can_vent: bool = false

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if total_flux == 0.0:
		total_flux = agent.ship_stats.flux
		delta = get_physics_process_delta_time()
	
	var flux_norm: float = (agent.soft_flux + agent.hard_flux) / total_flux
	
	agent.vent_flux_flag = false
	if (agent.posture == globals.Strategy.NEUTRAL or agent.posture == globals.Strategy.DEFENSIVE) and flux_norm >= def_neut_threshold:
		agent.vent_flux_flag = true
	elif agent.posture == globals.Strategy.OFFENSIVE and flux_norm >= offensive_threshold:
		agent.vent_flux_flag = true
	elif agent.posture == globals.Strategy.EVASIVE and flux_norm >= evasive_threshold:
		agent.vent_flux_flag = true
	
	if agent.combat_flag == false and flux_norm > 0.01:
		agent.vent_flux_flag = true
		can_vent = true
	elif agent.combat_flag == true and agent.vent_flux_flag == true:
		agent.fallback_flag = true
		can_vent = false
	
	if agent.vent_flux_flag == false:
		return FAILURE
	
	if agent.combat_flag == false and agent.fallback_flag == true:
		agent.fallback_flag = false
		agent.move_direction = Vector2.ZERO
	
	if agent.fallback_flag == true and agent.target_unit != null:
		agent.target_unit = null
	
	if can_vent == true:
		agent.move_direction == Vector2.ZERO
		if agent.soft_flux > 0.001:
			agent.soft_flux -= agent.ship_stats.flux_dissipation + agent.ship_stats.bonus_flux_dissipation
		elif agent.hard_flux > 0.001:
			agent.hard_flux -= agent.ship_stats.flux_dissipation + agent.ship_stats.bonus_flux_dissipation
		agent.update_flux_indicators()
	
	if agent.fallback_flag == true:
		agent.move_direction = -agent.transform.x
	
	return FAILURE
