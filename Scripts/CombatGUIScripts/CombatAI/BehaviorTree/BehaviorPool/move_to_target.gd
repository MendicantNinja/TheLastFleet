extends LeafAction

var targeted_ship_key: StringName = &"ship targeted"

func tick(agent: Ship, blackboard: Blackboard) -> int:
	var targeted_ship: Ship = blackboard.ret_data(targeted_ship_key)
	if targeted_ship == null:
		return FAILURE
	
	agent.move_to_targeted_ship(targeted_ship, blackboard)
	print(agent.position.distance_to(targeted_ship.position))
	if agent.position.distance_to(targeted_ship.position) < targeted_ship.furthest_safe_distance:
		return SUCCESS
	
	return RUNNING
