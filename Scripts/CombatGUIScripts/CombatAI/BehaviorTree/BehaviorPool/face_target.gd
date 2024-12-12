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
		if weapon_slot.can_look_at == true:
			oriented_count += 1
	
	if oriented_count == preferred_weapons.size():
		return SUCCESS
	
	var target_transform: Transform2D = Transform2D()
	for weapon_slot: WeaponSlot in preferred_weapons:
		var weapon_node: Node2D = weapon_slot.weapon_node
		target_transform = weapon_node.global_transform.looking_at(target.global_position)
		var scale_transform: Vector2 = weapon_node.scale
		target_transform = target_transform.scaled(scale_transform)
		required_orientation.push_back(target_transform)
	var test_transform: Transform2D = target_transform
	test_transform.origin = agent.global_position
	agent.transform = agent.transform.interpolate_with(test_transform, agent.rotational_delta)
	
	return RUNNING
