extends LeafAction

var target_key: StringName = &"target"

func tick(agent: Ship, blackboard: Blackboard) -> int:
	var target: Ship = blackboard.ret_data(target_key)
	if target == null:
		return RUNNING
	
	var in_range: bool = agent.get_target_into_range(target)
	if in_range:
		return SUCCESS
	
	return RUNNING
