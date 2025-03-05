extends LeafAction

var delta: float = 0.0
var time: float = 0.0
func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.target_unit != null:
		return FAILURE
	return SUCCESS
