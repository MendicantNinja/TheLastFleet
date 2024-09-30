extends RigidBody2D
class_name Ship

const SPEED = 3000.0
@onready var ShipNavigationAgent = $ShipNavigationAgent
var acceleration: Vector2 = Vector2.ZERO
var avoidance_velocity: Vector2 = Vector2.ZERO
var movement_delta: float = 0.0
var manual_control: bool = false
var ship_select: bool = false

func _ready() -> void:
	pass

# Any generic input event.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_mask == MOUSE_BUTTON_MASK_LEFT and ship_select:
			ShipNavigationAgent.set_target_position(event.global_position)  # move selected ship at event position
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
	
	var velocity = Vector2.ZERO
	movement_delta = SPEED * delta
	if not ShipNavigationAgent.is_navigation_finished():
		var ship_position: Vector2 = transform.get_origin()
		var next_path_position: Vector2 = ShipNavigationAgent.get_next_path_position()
		var direction_to_path: Vector2 = ship_position.direction_to(next_path_position)
		velocity = direction_to_path * movement_delta
		
		if avoidance_velocity != Vector2.ZERO:
			var direction_to_repath: Vector2 = velocity.direction_to(avoidance_velocity)
			var test_repath_x: int = direction_to_path.x - direction_to_repath.x
			var test_repath_y: int = direction_to_path.y - direction_to_repath.y
			if test_repath_x == 0.0:
				velocity.x += avoidance_velocity.x
			if test_repath_y == 0.0:
				velocity.y += avoidance_velocity.y
				
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
	avoidance_velocity = Vector2.ZERO
	if safe_velocity != Vector2.ZERO:
		avoidance_velocity = safe_velocity
