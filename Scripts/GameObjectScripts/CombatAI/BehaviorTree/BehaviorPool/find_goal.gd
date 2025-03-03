extends LeafAction

var radius: int = 30

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.is_friendly == true:
		return SUCCESS
	
	if Engine.get_physics_frames() % 487 != 0 or agent.group_leader == false:
		return FAILURE
	
	if agent.combat_goal == globals.GOAL.SKIRMISH and agent.goal_flag == true and agent.targeted_units.is_empty() == true:
		agent.goal_flag = false
		get_tree().call_group(agent.group_name, &"set_goal_flag", false)
	
	if agent.goal_flag == true:
		return SUCCESS
	
	var working_map: Imap = agent.working_map
	if agent.working_map == null:
		working_map = Imap.new(radius, radius)
	
	imap_manager.goal_map.add_into_map(working_map, agent.imap_cell.y, agent.imap_cell.x)
	agent.working_map = working_map
	var local_maximum: Dictionary = {}
	for m in range(radius):
		var maximum: float = working_map.map_grid[m].max()
		if maximum <= 0.0:
			continue
		var n: int = working_map.map_grid[m].find(maximum)
		var cell: Vector2i = Vector2i(agent.imap_cell.y + m, agent.imap_cell.x + n)
		local_maximum[maximum] = cell
	
	if local_maximum.is_empty():
		return FAILURE
	
	var cell_max: Vector2i = local_maximum[local_maximum.keys().max()]
	var target_position: Vector2 = Vector2(cell_max.y * imap_manager.default_cell_size, cell_max.x * imap_manager.default_cell_size)
	agent.set_navigation_position(target_position)
	return SUCCESS
