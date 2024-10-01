extends RigidBody2D
class_name Ship

const SPEED = 3000.0
@onready var ShipNavigationAgent = $ShipNavigationAgent
var acceleration: Vector2 = Vector2.ZERO
var avoidance_velocity: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO

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


	var ship_position: Vector2 = transform.get_origin()
	var raycast_result: Dictionary = {}
	var velocity = Vector2.ZERO
	movement_delta = SPEED * delta
	
	# Do these two branch statements when first detecting a collision. 
	if intermediate_pathing == false and target_position != Vector2.ZERO:
		print("Raycast shootout")
		var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, target_position, 1, [self])
		raycast_result = space_state.intersect_ray(query)
	
	if intermediate_pathing == false and not raycast_result.is_empty() and not ShipNavigationAgent.is_navigation_finished():
		print("Raycast shootout calculate and set new intermediate path")
		var collider_instance: Node = instance_from_id(raycast_result["collider_id"])
		#if collider_instance is 
		var collider_navagent: NavigationAgent2D = collider_instance.find_child("ShipNavigationAgent")
		if collider_navagent == null:
			return
		var collider_center: Vector2 = collider_instance.position
		var navagent_radius: int = collider_navagent.radius
		intermediate_pathing = true
		final_target_position = target_position
		target_position = Vector2(collider_center.x - navagent_radius/1.3, collider_center.y)
		target_position = Vector2(collider_center.x - navagent_radius, collider_center.y)
		ShipNavigationAgent.set_target_position(target_position)
	
	# Do this after finishing the intermediate pathing.
	elif intermediate_pathing == true and ShipNavigationAgent.is_navigation_finished():
		print("Intermediate pathing finished")
		target_position = final_target_position
		ShipNavigationAgent.set_target_position(target_position)
		intermediate_pathing = false
	
	# Normal Pathing
	elif not ShipNavigationAgent.is_navigation_finished():
		print("Pathing normally as navigation is not finished")
		var next_path_position: Vector2 = ShipNavigationAgent.get_next_path_position()
		var direction_to_path: Vector2 = ship_position.direction_to(next_path_position)
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
