extends LeafAction

var safe_distance: float = 0.0
var offensive_threshold: float = 0.9
var def_neut_threshold: float = 0.7
var evasive_threshold: float = 0.5
var default_radius: int = 10
var can_vent: bool = false

func tick(agent: Ship, blackboard: Blackboard) -> int:
	var flux_norm: float = (agent.soft_flux + agent.hard_flux) / agent.total_flux
	
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
	
	if agent.vent_flux_flag == true and can_vent == true and agent.shield_toggle == true:
		agent.set_shields(false)
	
	if agent.vent_flux_flag == false:
		return FAILURE
	
	if agent.combat_flag == false and agent.fallback_flag == true:
		agent.fallback_flag = false
		agent.move_direction = Vector2.ZERO
	
	if agent.fallback_flag == true and agent.target_unit != null:
		agent.target_unit.targeted_by.erase(agent)
		agent.target_unit = null
		agent.set_target_for_weapons(null)
	
	if can_vent == true:
		agent.move_direction == Vector2.ZERO
		if agent.soft_flux > 0.0:
			agent.soft_flux -= agent.ship_stats.flux_dissipation + agent.ship_stats.bonus_flux_dissipation
		elif agent.hard_flux > 0.0:
			agent.hard_flux -= agent.ship_stats.flux_dissipation + agent.ship_stats.bonus_flux_dissipation
		agent.update_flux_indicators()
	
	if agent.fallback_flag == true:
		agent.move_direction = -agent.transform.x
	
	return FAILURE
