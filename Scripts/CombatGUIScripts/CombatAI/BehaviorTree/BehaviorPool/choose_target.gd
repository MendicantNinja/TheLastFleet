extends LeafAction

var target_group_const: StringName = &" targets"
var target_key: StringName = &"target"

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if blackboard.has_data(target_key):
		return SUCCESS
	
	var agent_group_name: StringName = agent.group_name
	var target_group_key = agent_group_name + target_group_const
	
	var target: Ship = null
	var available_targets: Array = []
	if blackboard.has_data(target_group_key):
		available_targets = blackboard.ret_data(target_group_key)
	
	target = agent.find_closest_target(available_targets)
	if agent.group_leader == true and not blackboard.has_data(target_key):
		get_tree().call_group(agent_group_name, "set_blackboard_data", target_key, target)
		get_tree().call_group(agent_group_name, "set_blackboard_data", target_group_key, available_targets)
		blackboard.set_data(target_key, target)
	
	return SUCCESS
