extends LeafCondition

var target_key: StringName = &"target"
var threat_key: StringName = &"threats"

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if blackboard.has_data(threat_key):
		return SUCCESS
	return FAILURE
