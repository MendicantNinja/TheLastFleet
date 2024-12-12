extends LeafAction

var threats_key: StringName = &"threats"
var target_group_const: StringName = &" targets"
var target_key: StringName = &"target"

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if blackboard.has_data(target_key):
		return SUCCESS
	
	var threats: Array = blackboard.ret_data(threats_key)
	if not blackboard.has_data(agent.group_name + target_group_const):
		blackboard.set_data(agent.group_name + target_group_const, threats)
		return SUCCESS
	
	#var available_targets: Array = blackboard.ret_data(agent.group_name + target_group_const)
	#for n_threat in threats:
		#if not n_threat in available_targets:
			#available_targets.push_back(n_threat)
	#blackboard.set_data(agent.group_name + target_group_const, available_targets)
	
	return RUNNING
