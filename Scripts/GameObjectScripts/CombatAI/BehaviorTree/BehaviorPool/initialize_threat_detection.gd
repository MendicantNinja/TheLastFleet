extends LeafAction

var initialize_connections: bool = false
var threats_key: StringName = &"threats"
var target_key_suffix: StringName = &" targets"

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if initialize_connections == false:
		var all_weapons: Array = agent.all_weapons
		for weapon_slot: WeaponSlot in all_weapons:
			weapon_slot.new_threats.connect(blackboard._on_threat_detected.bind(threats_key, agent.group_name + target_key_suffix))
			weapon_slot.threat_exited.connect(blackboard._on_threat_exited.bind(threats_key, agent.group_name + target_key_suffix))
		initialize_connections = true
	return SUCCESS
