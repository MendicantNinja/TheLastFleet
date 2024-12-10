extends LeafCondition

var target_group_name: StringName = &" targets"
var target_key: StringName = &"target"

func tick(agent: Ship, blackboard: Blackboard) -> int:
	var agent_group_name: StringName = agent.group_name
	target_group_name = agent_group_name + target_group_name
	
	if agent.group_leader == true and blackboard.has_data(target_group_name) and not blackboard.has_data(target_key):
		get_tree().call_group(agent_group_name, "set_combat_ai", true)
		return SUCCESS
	
	if blackboard.has_data(target_group_name) or blackboard.has_data(target_key):
		return SUCCESS
	
	return FAILURE
