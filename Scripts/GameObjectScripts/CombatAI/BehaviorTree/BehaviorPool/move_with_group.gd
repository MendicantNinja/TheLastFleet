extends LeafAction

var slot_key: StringName = &"slot"
var target_area: Array = []
var target_position: Vector2 = Vector2.ZERO
var target_window: int = 0

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.group_leader == true or agent.group_name.is_empty():
		return SUCCESS
	
	if target_window == 0:
		target_window = agent.template_maps[imap_manager.MapType.OCCUPANCY_MAP].width
	
	var velocity: Vector2 = Vector2.ZERO
	var target_slot: Vector2i = Vector2i.ZERO
	if not blackboard.has_data(slot_key):
		return SUCCESS
	
	target_slot = blackboard.ret_data(slot_key)
	if target_area.is_empty():
		var start_cell: Vector2i = Vector2i(target_slot.x - target_window, target_slot.y - target_window)
		var end_cell: Vector2i = Vector2(target_slot.x + target_window, target_slot.y + target_window)
		target_area = [start_cell, end_cell]
	
	if target_position == Vector2.ZERO:
		target_position = Vector2(target_slot.y * imap_manager.default_cell_size, target_slot.x * imap_manager.default_cell_size)
	
	if agent.imap_cell == target_slot:
		var target_position: Vector2 = Vector2.ZERO
		blackboard.remove_data(slot_key)
		return SUCCESS
	
	var start_cell: Vector2i = target_area[0]
	var end_cell: Vector2i = target_area[1]
	var cell: Vector2i = agent.imap_cell
	
	var direction_to_target: Vector2 = agent.global_position.direction_to(target_position)
	velocity = direction_to_target * agent.movement_delta
	if cell.x >= start_cell.x && cell.y >= start_cell.y && cell.x <= end_cell.x && cell.y <= end_cell.y:
		velocity /= 2
	var ease_velocity: Vector2 = Vector2.ZERO
	var normalize_velocity_x: float = agent.linear_velocity.x / velocity.x
	var normalize_velocity_y: float = agent.linear_velocity.y / velocity.y
	if velocity.x == 0.0:
		normalize_velocity_x = 0.0
	if velocity.y == 0.0:
		normalize_velocity_y = 0.0
	ease_velocity.x = (velocity.x + agent.linear_velocity.x) * ease(normalize_velocity_x, agent.ship_stats.acceleration)
	ease_velocity.y = (velocity.y + agent.linear_velocity.y) * ease(normalize_velocity_y, agent.ship_stats.acceleration)
	velocity += ease_velocity
	
	var look_at: Transform2D = agent.transform.looking_at(target_position)
	agent.transform = agent.transform.interpolate_with(look_at, agent.rotational_delta)
	
	agent.acceleration = velocity - agent.linear_velocity
	
	if (agent.acceleration.abs().floor() != Vector2.ZERO or agent.manual_control) and agent.sleeping:
		agent.sleeping = false
	
	return RUNNING
