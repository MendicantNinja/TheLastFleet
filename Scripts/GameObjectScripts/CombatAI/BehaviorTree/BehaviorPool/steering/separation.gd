extends LeafAction

var fof_radius: float = 0.0
var rad_coe: float = 4.0
var time: float = 0.0
var delta: float = 0.0

func tick(agent: Ship, blackboard: Blackboard) -> int:
	if fof_radius == 0.0:
		fof_radius = agent.ShipNavigationAgent.radius * rad_coe
	
	if delta == 0.0:
		delta = get_physics_process_delta_time()
	#
	#if agent.target_unit == null:
		#return SUCCESS
	
	var neighbors: Array = agent.neighbor_units
	var friendly_neighbors: Array = []
	for unit in neighbors:
		if agent.is_friendly == true and unit.is_friendly == true:
			friendly_neighbors.append(unit)
		elif agent.is_friendly == false and unit.is_friendly == false:
			friendly_neighbors.append(unit)
	
	var velocity: Vector2 = Vector2.ZERO
	var strafe_direction: Dictionary = {}
	var agent_fof: float = fof_radius * fof_radius
	for neighbor in friendly_neighbors:
		var neighbor_fof: float = neighbor.ShipNavigationAgent.radius * rad_coe
		neighbor_fof *= neighbor_fof
		var square_dist: float = neighbor.global_position.distance_squared_to(agent.global_position)
		if square_dist > (agent_fof + neighbor_fof):
			continue
		
		var direction_to_neighbor: Vector2 = agent.global_position.direction_to(neighbor.global_position)
		var direction_angle: float = agent.transform.x.angle_to(direction_to_neighbor)
		if direction_angle < 0.0:
			strafe_direction[square_dist] = agent.transform.y
		if direction_angle > 0.0:
			strafe_direction[square_dist] = -agent.transform.y
	
	if strafe_direction.is_empty() == true:
		time = 0.0
		return FAILURE
	
	var speed: float = agent.ship_stats.acceleration
	var speed_modifier: float = 0.0
	if (agent.soft_flux + agent.hard_flux) == 0.0:
		speed += agent.zero_flux_bonus
	time += delta + agent.time_coefficient
	if time > 4.0:
		time = 0.0
	var separation_velocity: Vector2 = strafe_direction[strafe_direction.keys().min()] * speed * time
	var new_velocity: Vector2 = agent.heur_velocity + separation_velocity * 0.2
	if agent.combat_flag == true or agent.target_unit != null:
		new_velocity = separation_velocity
	
	agent.time = time
	agent.heur_velocity = new_velocity.limit_length(agent.speed)
	agent.acceleration = new_velocity.limit_length(agent.speed)
	return FAILURE
