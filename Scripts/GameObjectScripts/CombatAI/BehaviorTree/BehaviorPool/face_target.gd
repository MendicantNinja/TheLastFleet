extends LeafAction

var target_key: StringName = &"target"

func tick(agent: Ship, blackboard: Blackboard) -> int:
	var target = blackboard.ret_data(target_key)
	if target == null:
		return RUNNING
	
	var preferred_weapons: Array = agent.all_weapons
	var oriented_count: int = 0
	var required_orientation: Array = []
	for weapon_slot: WeaponSlot in preferred_weapons:
		var weapon_node: Node2D = weapon_slot.weapon_node
		var target_transform: Transform2D = weapon_node.global_transform.looking_at(target.global_position)
		var dot_product: float = weapon_slot.default_direction.x.dot(target_transform.x)
		var angle_to_node: float = acos(dot_product)
		if angle_to_node < weapon_slot.arc_in_radians or dot_product > 0:
			oriented_count += 1
		required_orientation.push_back(target_transform)
	
	if oriented_count == preferred_weapons.size() - 1:
		return SUCCESS
	
	var test_transform: Transform2D = required_orientation[0]
	test_transform.origin = agent.global_position
	agent.transform = agent.transform.interpolate_with(test_transform, agent.rotational_delta)
	
	return FAILURE
