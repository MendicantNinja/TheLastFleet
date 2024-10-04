extends RigidBody2D
class_name Ship

const SPEED = 3000.0
@onready var ShipNavigationAgent = $ShipNavigationAgent
var acceleration: Vector2 = Vector2.ZERO
var avoidance_velocity: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var navigation_path

# Used for intermediate pathing around dynamic agents
var final_target_position: Vector2 = Vector2.ZERO
var intermediate_pathing: bool = false

var movement_delta: float = 0.0
var ship_select: bool = false

func _ready() -> void:
	pass

# Any generic input event.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_mask == MOUSE_BUTTON_MASK_LEFT and ship_select:
			intermediate_pathing = false
			target_position = event.global_position
			ShipNavigationAgent.set_target_position(target_position)  # move selected ship at event position
		elif event.pressed and event.button_mask == MOUSE_BUTTON_MASK_RIGHT and ship_select:
			ship_select = false # deselect ship by right clicking anywhere
	
	if event is InputEventKey:
		pass

# When the player interacts with the ship via mouse.
func _on_input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_mask == MOUSE_BUTTON_MASK_LEFT and not ship_select:
			ship_select = true # select ship
		elif event.pressed and event.button_mask == MOUSE_BUTTON_MASK_LEFT and ship_select:
			ship_select = false # deselect ship

func _physics_process(delta: float) -> void:
	if NavigationServer2D.map_get_iteration_id(ShipNavigationAgent.get_navigation_map()) == 0:
		return

#collider: The colliding object.
#
#collider_id: The colliding object's ID.
#
#normal: The object's surface normal at the intersection point, or Vector2(0, 0) if the ray starts inside the shape and PhysicsRayQueryParameters2D.hit_from_inside is true.
#
#position: The intersection point.
#
#rid: The intersecting object's RID.
#
#shape: The shape index of the colliding shape.


	var ship_origin: Vector2 = transform.get_origin()
	var query_for_target: Dictionary = {}
	var query_for_ship: Dictionary = {}
	var velocity = Vector2.ZERO
	movement_delta = SPEED * delta
	
	# Do these two branch statements when first detecting a collision. 
	if intermediate_pathing == false and target_position != Vector2.ZERO:
		#print("Raycast shootout")
		#navigation_path = ShipNavigationAgent.get_current_navigation_path()
		var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, target_position, 1, [self])
		query_for_ship = space_state.intersect_ray(query)
		if not query_for_ship.is_empty():
			var collider_instance: Node = instance_from_id(query_for_ship["collider_id"])
			var collider_center: Vector2 = collider_instance.position
			query = PhysicsRayQueryParameters2D.create(target_position, collider_center, 1, [self])
			query_for_target = space_state.intersect_ray(query)
	
	var sweep_end_vector: Vector2 = Vector2.ZERO
	var sweep_start_vector: Vector2 = Vector2.ZERO
	var sweep_vectors: Array = []
	if not query_for_ship.is_empty():
		# flip the direction of the raycast normal to make it face the collider
		var target_direction: Vector2 = -1*query_for_target["normal"]
		
		# get the starting vectors needed for a clockwise sweep
		sweep_end_vector = target_direction.rotated(PI/4)
		sweep_start_vector = target_direction.rotated(-PI/4)
		
		# find the distance from the target position to the intersection and 
		# add the nav agent radius for good measure
		var collider_instance: Node = instance_from_id(query_for_ship["collider_id"])
		var collider_navagent: NavigationAgent2D = collider_instance.find_child("ShipNavigationAgent")
		if collider_navagent == null:
			return
		var navagent_radius: int = collider_navagent.radius
		var intersection_position: Vector2 = query_for_ship["position"]
		var sweep_radius: float = target_position.distance_to(intersection_position) + navagent_radius * 2
		
		# find the vectors required to offset the sweep start and end vectors
		var offset_start_vector: Vector2 = Vector2(sweep_start_vector.x * sweep_radius, sweep_start_vector.y * sweep_radius)
		var offset_end_vector: Vector2 = Vector2(sweep_end_vector.x * sweep_radius, sweep_end_vector.y * sweep_radius)
		
		sweep_start_vector = Vector2(target_position.x + offset_start_vector.x, target_position.y + offset_start_vector.y)
		sweep_end_vector = Vector2(target_position.x + offset_end_vector.x, target_position.y + offset_end_vector.y)
		
		# second verse same as the first
		# we're manually incrementing the direction, all the math is the same
		sweep_vectors.push_back(sweep_start_vector)
		var new_sweep_direction: Vector2 = target_direction.rotated(-PI/4)
		for i in range(7):
			new_sweep_direction = new_sweep_direction.rotated(PI/16)
			var offset_vector: Vector2 = Vector2(new_sweep_direction.x * sweep_radius, new_sweep_direction.y * sweep_radius)
			var new_sweep_vector = Vector2(target_position.x + offset_vector.x, target_position.y + offset_vector.y)
			sweep_vectors.push_back(new_sweep_vector)
		sweep_vectors.push_back(sweep_end_vector)
	
	# now we actually sweep each vector and detect for collisions
	var valid_paths: Array = []
	if sweep_start_vector != Vector2.ZERO and sweep_end_vector != Vector2.ZERO:
		var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		var query: PhysicsRayQueryParameters2D
		var query_results: Dictionary = {}
		for vector in sweep_vectors:
			query = PhysicsRayQueryParameters2D.create(target_position, vector, 7, [self])
			query_results = space_state.intersect_ray(query)
			if query_results.is_empty():
				valid_paths.push_back(vector)
				print("valid vector: ", vector)
			else:
				print("invalid vector: ", vector)
	
	if intermediate_pathing == false and not query_for_target.is_empty() and not ShipNavigationAgent.is_navigation_finished():
		#print("Raycast shootout calculate and set new intermediate path")
		var collider_instance: Node = instance_from_id(query_for_target["collider_id"])
		#if collider_instance is 
		var collider_navagent: NavigationAgent2D = collider_instance.find_child("ShipNavigationAgent")
		if collider_navagent == null:
			return
		var collider_center: Vector2 = collider_instance.position
		var navagent_radius: int = collider_navagent.radius
		intermediate_pathing = true
		final_target_position = target_position
		target_position = Vector2(collider_center.x - navagent_radius, collider_center.y)
		ShipNavigationAgent.set_target_position(target_position)
	
	# Do this after finishing the intermediate pathing.
	elif intermediate_pathing == true and ShipNavigationAgent.is_navigation_finished():
		#print("Intermediate pathing finished")
		target_position = final_target_position
		ShipNavigationAgent.set_target_position(target_position)
		intermediate_pathing = false
	
	# Normal Pathing
	if not ShipNavigationAgent.is_navigation_finished():
		#print("Pathing normally as navigation is not finished")
		var next_path_position: Vector2 = ShipNavigationAgent.get_next_path_position()
		var direction_to_path: Vector2 = ship_origin.direction_to(next_path_position)
		velocity = direction_to_path * movement_delta
		
		var transform_look_at: Transform2D = transform.looking_at(next_path_position)
		transform = transform.interpolate_with(transform_look_at, delta)
	
	
	acceleration += velocity - linear_velocity
	
	var force: Vector2 = mass * acceleration
	linear_velocity = Vector2.ZERO
	if force.abs().floor() != Vector2.ZERO:
		apply_central_force(force)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if ShipNavigationAgent.is_navigation_finished() :
		# decrease linear velocity to converge acceleration to zero, thus
		# converging force to zero
		linear_velocity += lerp(Vector2.ZERO, -linear_velocity, state.step)
	# use apply_impulse for one-shot calculations for collisions
	# its time-independent hence why its a one-shot

func _on_ShipNavigationAgent_velocity_computed(safe_velocity):
	pass
	#avoidance_velocity = Vector2.ZERO
	#if safe_velocity != Vector2.ZERO:
		#avoidance_velocity = safe_velocity
