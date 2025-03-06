extends LeafAction

var target_position: Vector2 = Vector2.ZERO
var occupancy_radius: float = 0.0
var delta: float = 0.0
var time: float = 0.0

var default_radius: int = 10
var target_coefficient: float = 0.95

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if agent.target_position == Vector2.ZERO:
		target_position = Vector2.ZERO
		time = 0.0
		return SUCCESS
	
	if occupancy_radius == 0.0:
		delta = get_physics_process_delta_time()
		var radius: int = agent.template_maps[imap_manager.MapType.OCCUPANCY_MAP].width - 1
		occupancy_radius = (radius * imap_manager.default_cell_size) * target_coefficient
	
	var velocity: Vector2 = Vector2.ZERO
	agent.heur_velocity = velocity
	
	if agent.group_leader == false and agent.target_position != target_position:
		target_position = agent.target_position
	elif agent.group_leader == true and target_position != agent.target_position:
		target_position = agent.target_position
		
		if not imap_manager.working_maps.has(agent.group_name):
			var cell = Vector2i(agent.target_position.y / imap_manager.default_cell_size, agent.target_position.x / imap_manager.default_cell_size)
			var height: int = default_radius * imap_manager.default_cell_size
			var width: int = default_radius * imap_manager.default_cell_size
			var working_map: Imap = Imap.new(width, height, 0.0, 0.0, imap_manager.default_cell_size)
			working_map.map_type = imap_manager.MapType.INFLUENCE_MAP
			imap_manager.agent_maps[imap_manager.MapType.INFLUENCE_MAP].add_into_map(working_map, cell.y, cell.x)
			imap_manager.working_maps[agent.group_name] = working_map
	
	var direction_to_path: Vector2 = agent.global_position.direction_to(target_position)
	
	var speed_modifier: float = 0.0
	if (agent.soft_flux + agent.hard_flux) == 0.0 and speed_modifier != agent.zero_flux_bonus:
		speed_modifier += agent.zero_flux_bonus
	
	var speed: float = agent.ship_stats.acceleration + speed_modifier
	if agent.brake_flag == true:
		speed = agent.ship_stats.deceleration
	
	time += delta + agent.time_coefficient
	if time > 4.0:
		time = 0.0
	
	velocity = direction_to_path * speed * time
	
	var distance_to: float = agent.global_position.distance_to(agent.target_position)
	if agent.target_position != Vector2.ZERO and agent.target_unit == null:
		if agent.successful_deploy == false and distance_to < 25.0 and agent.group_leader == false:
			agent.successful_deploy = true
			agent.group_remove(agent.group_name)
		
		if distance_to < 25.0:
			agent.target_position = Vector2.ZERO
			agent.heur_velocity = Vector2.ZERO
			agent.acceleration = Vector2.ZERO
			time = 0.0
			return SUCCESS
		
		var brake_distance: float = (agent.linear_velocity.length() ** 2) / (2.0 * agent.ship_stats.deceleration)
		if distance_to <= brake_distance:
			agent.brake_flag == true
			velocity = -agent.linear_velocity.normalized() * agent.ship_stats.deceleration * time
	
	velocity = velocity.limit_length(agent.speed)
	agent.heur_velocity = velocity
	agent.time = time
	agent.acceleration = velocity
	return FAILURE
