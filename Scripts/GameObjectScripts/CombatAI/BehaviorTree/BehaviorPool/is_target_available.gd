extends LeafCondition

var target_group_const: StringName = &" targets"
var target_key: StringName = &"target"
var threat_key: StringName = &"threats"

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if blackboard.has_data(target_key):
		return SUCCESS
	
	var agent_group_name: StringName = agent.group_name
	var target_group_key: StringName = agent_group_name + target_group_const
	var available_targets: Array = []
	if blackboard.has_data(target_group_key):
		available_targets = blackboard.ret_data(target_group_key)
	
	var threats_detected: Array = []
	if blackboard.has_data(threat_key):
		threats_detected = blackboard.ret_data(threat_key)
	
	if not threats_detected.is_empty() and available_targets.is_empty():
		blackboard.set_data(target_group_key, threats_detected)
	
	if agent.group_leader == true and blackboard.has_data(target_group_key) and not blackboard.has_data(target_key):
		return SUCCESS
	
	return FAILURE
