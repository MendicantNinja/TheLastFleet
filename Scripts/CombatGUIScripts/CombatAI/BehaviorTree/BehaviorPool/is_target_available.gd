extends LeafCondition

var target_group_const: StringName = &" targets"
var target_key: StringName = &"target"

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if blackboard.has_data(target_key):
		return SUCCESS
	
	var agent_group_name: StringName = agent.group_name
	var target_group_key: StringName = agent_group_name + target_group_const
	var available_targets: Array = []
	if blackboard.has_data(target_group_key):
		available_targets = blackboard.ret_data(target_group_key)
	
	if available_targets.is_empty() and blackboard.has_data(target_group_key):
		blackboard.remove_data(target_group_key)
	
	if agent.group_leader == true and blackboard.has_data(target_group_key) and not blackboard.has_data(target_key):
		get_tree().call_group(agent_group_name, "set_combat_ai", true)
		return SUCCESS
	
	return FAILURE
