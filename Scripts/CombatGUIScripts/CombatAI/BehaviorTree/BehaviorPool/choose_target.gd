extends LeafAction

var target_group_name: StringName = &" target"
var targeted_ship_key: StringName = &"ship targeted"

func tick(agent: Ship, blackboard: Blackboard) -> int:
	var unit_group_name: StringName = agent.group_name
	target_group_name = unit_group_name + target_group_name
	if not blackboard.has_data(target_group_name):
		return FAILURE
	
	var available_targets: Dictionary = blackboard.has_data(target_group_name)
	
	
	
	return RUNNING
