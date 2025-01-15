extends LeafAction

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 240 != 0:
		return FAILURE
	
	var awaiting_order_idx: int = agent.awaiting_orders.size() - 1
	var current_group = agent.awaiting_orders[awaiting_order_idx]
	
	var move_order: Vector2
	if agent.queue_orders.has(agent.target_key):
		var target: Array = agent.queue_orders[agent.target_key]
		var target_cell: Vector2i = target[0].registry_cell
		move_order = Vector2(target_cell.x - 1, target_cell.y)
	
	agent.queue_orders[agent.move_key] = move_order
	return FAILURE
