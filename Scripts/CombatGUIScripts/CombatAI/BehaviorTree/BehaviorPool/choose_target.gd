extends LeafAction

var target_group_name: StringName = &" targets"
var target_key: StringName = &"target"

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if blackboard.has_data(target_key):
		return SUCCESS
	
	var agent_group_name: StringName = agent.group_name
	target_group_name = agent_group_name + target_group_name
	
	var target: Ship = null
	var available_targets: Array = blackboard.ret_data(target_group_name)
	target = agent.find_closest_target(available_targets)
	if agent.group_leader and not blackboard.has_data(target_key):
		get_tree().call_group(agent_group_name, "set_group_blackboard_data", target_key, target)
	blackboard.set_data(target_key, target)
	
	return SUCCESS
