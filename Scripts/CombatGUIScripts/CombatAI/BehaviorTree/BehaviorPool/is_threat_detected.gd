extends LeafCondition

var target_key: StringName = &"target"
var threat_key: StringName = &"threats"

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if blackboard.has_data(target_key):
		return SUCCESS 
	
	if not blackboard.has_data(threat_key):
		blackboard.set_data(threat_key, [])
		var all_weapons: Array = agent.all_weapons
		for weapon_slot in all_weapons:
			weapon_slot.new_threats.connect(blackboard._on_threat_detected.bind(threat_key))
			weapon_slot.update_threats.connect(blackboard._on_threat_exited.bind(threat_key))
	
	var threats: Array = blackboard.ret_data(threat_key)
	if not threats.is_empty():
		return SUCCESS
	
	return FAILURE
