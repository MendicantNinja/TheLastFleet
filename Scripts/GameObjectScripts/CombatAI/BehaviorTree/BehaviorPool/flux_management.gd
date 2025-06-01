extends LeafAction

var offensive_threshold: float = 0.8
var def_neut_threshold: float = 0.7
var evasive_threshold: float = 0.5
var vent_flux: bool = false:
	set(value):
		vent_flux = value

func tick(agent: Ship, blackboard: Blackboard) -> int:
	var flux_norm: float = (agent.soft_flux + agent.hard_flux) / agent.total_flux
	if agent.combat_flag == false and flux_norm > 0.0 and agent.vent_flux_flag == false:
		agent.vent_flux_flag = true
		for weapon in agent.all_weapons:
			weapon.vent_flux = true
	
	if agent.soft_flux == 0.0 and agent.hard_flux == 0.0 and vent_flux == true and agent.fallback_flag == true:
		print("%s no longer in combat and vented flux" % [agent.name])
		vent_flux = false
		agent.fallback_flag = false
		agent.move_direction = Vector2.ZERO
	
	if flux_norm == 0.0 and vent_flux == true:
		vent_flux = false
	
	if (agent.posture == globals.Strategy.NEUTRAL or agent.posture == globals.Strategy.DEFENSIVE) and flux_norm >= def_neut_threshold:
		vent_flux = true
	elif agent.posture == globals.Strategy.OFFENSIVE and flux_norm >= offensive_threshold:
		vent_flux = true
	elif agent.posture == globals.Strategy.EVASIVE and flux_norm >= evasive_threshold:
		vent_flux = true
	
	if vent_flux == true and agent.combat_flag == true and agent.fallback_flag == false:
		agent.fallback_flag = true
		agent.move_direction = -agent.transform.x
		print("%s in combat and falling back to vent flux" % [agent.name])
	
	if vent_flux == true and agent.combat_flag == true and agent.target_unit != null:
		agent.target_unit.targeted_by.erase(agent)
		agent.target_unit == null
		agent.set_target_for_weapons(null)
	
	return FAILURE
