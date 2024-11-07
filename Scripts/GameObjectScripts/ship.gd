extends RigidBody2D
class_name Ship


@onready var ShipNavigationAgent = $ShipNavigationAgent
@onready var NavigationTimer = $NavigationTimer
@onready var RepathArea = $RepathArea
@onready var RepathShape = $RepathArea/RepathShape
@onready var ShipSprite = $ShipSprite

@onready var CombatMap: Node2D = get_parent()
@onready var TacticalMapIcon = $TacticalMapIcon
@onready var TacticalMap = CombatMap.get_node("%TacticalMap")
@onready var ManualControlIndicator = $ManualControlIndicator
@onready var all_weapons: Array[WeaponSlot]

# Temporary variables
# Should group weapon slots in the near future instead of this, 
# even though call_group() broke in 4.3 stable.
@onready var WeaponSlot0 = $WeaponSlot0
@onready var WeaponSlot1 = $WeaponSlot1

var ship_stats: ShipStats
var speed: float = 0.0
var hull_integrity: float = 0.0
#var is_player: bool = false # For player-affiliated ships
var is_friendly: bool = false # For friendly NPC ships (I love three-party combat) 
var manual_control: bool = false:
	set(value):
		if value == false:
			ManualControlIndicator.visible = false
			manual_control = false
		elif value == true:
			ManualControlIndicator.visible = true
			manual_control = true
var rotate_angle: float = 0.0
var move_direction: Vector2 = Vector2.ZERO

# Used for targeting and weapons.
var aim_direction: Vector2 = Vector2.ZERO
var mouse_hover: bool = false

# Used for intermediate pathing around dynamic agents
var final_target_position: Vector2 = Vector2.ZERO
var intermediate_pathing: bool = false
var acceleration: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var movement_delta: float = 0.0
var ship_select: bool = false:
	set(value):
		if value == true: 
			TacticalMapIcon.button_pressed = true # Pressed is solely for GUI effects (brighten) with regards to the TacMapIcon.
			ship_select = value
		elif value == false:
			TacticalMapIcon.button_pressed = false
			ship_select = value
			

# Comment this out if it causes trouble. Used for initializing ships into combat based on stored fleet data. Should be called before ready/entering the ship into the scene.
func initialize(p_ship_stats: ShipStats = ShipStats.new(data.ship_type_enum.TEST)) -> void:
	ship_stats = p_ship_stats

# Any adjustments before deploying the ship to the combat space. Called during/by FleetDeployment.
func deploy_ship() -> void:
	if is_friendly == true:
		TacticalMapIcon.texture_normal = load("res://Art/CombatGUIArt/tac_map_player_ship.png")
		TacticalMapIcon.texture_pressed = load("res://Art/CombatGUIArt/tac_map_player_ship_selected.png")
		TacticalMapIcon.modulate = settings.player_color
		TacticalMapIcon.pivot_offset = Vector2(TacticalMapIcon.size.x/2, TacticalMapIcon.size.y/2)
		TacticalMapIcon.custom_minimum_size = Vector2(RepathShape.shape.radius, RepathShape.shape.radius) * 1.6
		ManualControlIndicator.self_modulate = settings.player_color
	elif is_friendly == false:
		# Non-identical to is_friendly == true Later in development. Swap these rectangle pictures with something else. (Starsector uses diamonds for enemies).
		TacticalMapIcon.texture_normal = load("res://Art/CombatGUIArt/tac_map_player_ship.png")
		TacticalMapIcon.texture_pressed = load("res://Art/CombatGUIArt/tac_map_player_ship_selected.png")
		TacticalMapIcon.modulate = settings.enemy_color
		TacticalMapIcon.custom_minimum_size = Vector2(self.RepathShape.shape.radius, self.RepathShape.shape.radius) * 1.6
	# Ship is ready and has entered the scene tree.
	if TacticalMap.visible == true:
		TacticalMapIcon.show()

# Custom signals.
signal ship_targeted(ship_id)

func _ready() -> void:
	if ship_stats == null:
		ship_stats = ShipStats.new(data.ship_type_enum.TEST)
	speed = ship_stats.top_speed
	
	var ship_hull = ship_stats.ship_hull
	ShipSprite.texture = ship_hull.ship_sprite
	hull_integrity = ship_hull.hull_integrity
	ShipSprite.self_modulate = settings.player_color
	
	var repath_shape: Shape2D = CircleShape2D.new()
	repath_shape.radius = ShipNavigationAgent.radius
	RepathShape.shape = repath_shape
	RepathArea.collision_layer = collision_layer
	RepathArea.collision_mask = collision_mask
	
	if collision_layer == 1: # simplifies some things but definitely not a permanent solution
		add_to_group("friendly")
		is_friendly = true
		rotation -= PI/2
	else:
		add_to_group("enemy")
		rotation += PI/2
	
	# Assigns weapon slots based on what's in the ship scene.
	for child in get_children():
		if child is WeaponSlot:
			all_weapons.append(child)
			child.detection_parameters(collision_mask, is_friendly, get_rid())
	for i in range(all_weapons.size()):
		# Temporary hack to test weapons so that the mounts aren't empty.
		# MENDICANT ONLY: all_weapons[i]=ship_stats.weapon_slots[i] make sure that ship stats 
		# assigns the child nodes like WeaponMountSprite and WeaponSprite or else they will be 
		# null and cause errors.
		all_weapons[i].set_weapon_slot(data.weapon_dictionary.get(data.weapon_enum.RAILGUN))
		# In the future, weapons will automatically be assigned from the already existing weapons in 
		# ship_stats during fleet deployment. Unfortunately refitting + save/load isn't in yet so 
		# everything is a railgun.
	
	toggle_auto_aim(all_weapons)
	toggle_auto_fire(all_weapons)
	self.input_event.connect(_on_input_event)
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)
	

#ooooo ooooo      ooo ooooooooo.   ooooo     ooo ooooooooooooo 
#`888' `888b.     `8' `888   `Y88. `888'     `8' 8'   888   `8 
 #888   8 `88b.    8   888   .d88'  888       8       888      
 #888   8   `88b.  8   888ooo88P'   888       8       888      
 #888   8     `88b.8   888          888       8       888      
 #888   8       `888   888          `88.    .8'       888      
#o888o o8o        `8  o888o           `YbodP'        o888o    

# Any generic input event.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if TacticalMap.visible and event.pressed and event.button_mask == MOUSE_BUTTON_MASK_RIGHT and ship_select :
			intermediate_pathing = false
			target_position = get_global_mouse_position()
			ShipNavigationAgent.set_target_position(target_position)  # move selected ship at event position
	elif event is InputEventKey:
		if is_friendly:
			if (event.keycode == KEY_T and event.pressed) and ship_select:
				toggle_manual_control()
				toggle_manual_aim(all_weapons) # Replace all_weapons with specific weapon systems configured in the ship refit screen from ship stats.
			elif (event.keycode == KEY_C and event.pressed) and ship_select and manual_control:
				toggle_auto_aim(all_weapons)
			elif (event.keycode == KEY_V and event.pressed) and ship_select and manual_control:
				toggle_auto_fire(all_weapons)
		elif not is_friendly: # for non-player/enemy ships
			if (event.keycode == KEY_R and event.pressed) and mouse_hover:
				var target_ship_id = get_rid()
				emit_signal("ship_targeted", get_rid())
		else:
			if (event.keycode == KEY_F and event.is_pressed()):
				fire_weapon_slot(all_weapons[0])
			if (event.keycode == KEY_Q and event.is_pressed()):
				fire_weapon_system(all_weapons)

# When the player interacts with a ship via mouse.
func _on_input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	# This may end up disrupting drag by handling the input too early. Look for a manual "input == not handled" function later if needed.
	if CombatMap.dragging == true:
		return
	if event is InputEventMouseButton and is_friendly == true and TacticalMap.visible == true:
		if event.pressed and event.button_mask == MOUSE_BUTTON_MASK_LEFT and not ship_select:
			ship_select = true # select ship
			
		elif event.pressed and event.button_mask == MOUSE_BUTTON_MASK_LEFT and ship_select:
			ship_select = false # deselect ship

func _on_mouse_entered() -> void:
	mouse_hover = true

func _on_mouse_exited() -> void:
	mouse_hover = false

func toggle_manual_control() -> void:
	# The visible indicator is turned on and off by the manual control variable's custom setter. Otherwise recursion issues occur.
	#CombatMap.TacticalMap.display_tactical_map()
	if not manual_control:
		if CombatMap.controlled_ship != null:
			CombatMap.controlled_ship.manual_control = false
			# Switch all_weapons back to autofiring on the old ship we're switching from.
			CombatMap.controlled_ship.toggle_manual_aim(all_weapons)
		manual_control = true
		CombatMap.controlled_ship = self
	else:
		
		manual_control = false

#oooooo   oooooo     oooo oooooooooooo       .o.       ooooooooo.     .oooooo.   ooooo      ooo  .oooooo..o 
 #`888.    `888.     .8'  `888'     `8      .888.      `888   `Y88.  d8P'  `Y8b  `888b.     `8' d8P'    `Y8 
  #`888.   .8888.   .8'    888             .8"888.      888   .d88' 888      888  8 `88b.    8  Y88bo.      
   #`888  .8'`888. .8'     888oooo8       .8' `888.     888ooo88P'  888      888  8   `88b.  8   `"Y8888o.  
	#`888.8'  `888.8'      888    "      .88ooo8888.    888         888      888  8     `88b.8       `"Y88b 
	 #`888'    `888'       888       o  .8'     `888.   888         `88b    d88'  8       `888  oo     .d8P 
	  #`8'      `8'       o888ooooood8 o88o     o8888o o888o         `Y8bood8P'  o8o        `8  8""88888P'  

func _on_ship_targeted(ship_id: RID) -> void:
	if not ship_select:
		return
	
	for weapon in all_weapons:
		weapon.set_target_ship(ship_id)

func fire_weapon_system(weapon_system: Array[WeaponSlot]) -> void:
	for weapon_slot in weapon_system:
		fire_weapon_slot(weapon_slot)

func fire_weapon_slot(weapon_slot: WeaponSlot) -> void:
	var ship_id = get_rid().get_id()
	weapon_slot.fire(ship_id)

func toggle_manual_aim(weapon_system: Array[WeaponSlot]) -> void:
	for weapon_slot in weapon_system:
		weapon_slot.set_manual_aim()

func toggle_auto_aim(weapon_system: Array[WeaponSlot]) -> void:
	for weapon_slot in weapon_system:
		weapon_slot.set_auto_aim()

func toggle_auto_fire(weapon_system: Array[WeaponSlot]) -> void:
	for weapon_slot in weapon_system:
		weapon_slot.set_auto_fire()

#func _on_EffectiveRange_body_exited(body: Node2D) -> void:
	#pass
#ooooo      ooo       .o.       oooooo     oooo ooooo   .oooooo.          .o.       ooooooooooooo ooooo   .oooooo.   ooooo      ooo 
#`888b.     `8'      .888.       `888.     .8'  `888'  d8P'  `Y8b        .888.      8'   888   `8 `888'  d8P'  `Y8b  `888b.     `8' 
 #8 `88b.    8      .8"888.       `888.   .8'    888  888               .8"888.          888       888  888      888  8 `88b.    8  
 #8   `88b.  8     .8' `888.       `888. .8'     888  888              .8' `888.         888       888  888      888  8   `88b.  8  
 #8     `88b.8    .88ooo8888.       `888.8'      888  888     ooooo   .88ooo8888.        888       888  888      888  8     `88b.8  
 #8       `888   .8'     `888.       `888'       888  `88.    .88'   .8'     `888.       888       888  `88b    d88'  8       `888  
#o8o        `8  o88o     o8888o       `8'       o888o  `Y8bood8P'   o88o     o8888o     o888o     o888o  `Y8bood8P'  o8o        `8  
																																   
func _physics_process(delta: float) -> void:
	if NavigationServer2D.map_get_iteration_id(ShipNavigationAgent.get_navigation_map()) == 0:
		return
		
	var velocity: Vector2 = Vector2.ZERO
	
	if movement_delta == 0.0:
		movement_delta = speed * delta
	
	if manual_control:
		var rotate_direction: Vector2 = Vector2(0, Input.get_action_strength("E") - Input.get_action_strength("Q"))
		rotate_angle = rotate_direction.angle()
		move_direction = Vector2(Input.get_action_strength("W") - Input.get_action_strength("S"),
		Input.get_action_strength("D") - Input.get_action_strength("A"))
	
	if rotate_angle != 0.0:
		var adjust_mass: float = (mass * 1000)
		rotate_angle = rotate_angle * adjust_mass * ship_stats.turn_rate
	
	if move_direction != Vector2.ZERO:
		var rotate_movement: Vector2 = move_direction.rotated(transform.x.angle())
		velocity = rotate_movement * movement_delta
		velocity += ease_velocity(velocity)
	
	if manual_control and Input.is_action_pressed("m1"):
		fire_weapon_system(all_weapons)
	
	if ShipNavigationAgent.get_max_speed() != movement_delta:
		ShipNavigationAgent.set_max_speed(movement_delta)
	
	var ship_query: Dictionary = {}
	if not ShipNavigationAgent.is_navigation_finished():
		ship_query = collision_raycast(global_position, target_position, 7, true, false)
	
	var sweep_vectors: Array[Vector2] = []
	if not ship_query.is_empty():
		var collider_instance: Node = instance_from_id(ship_query["collider_id"])
		var collider_center: Vector2 = collider_instance.global_position
		var target_query: Dictionary = collision_raycast(target_position, collider_center, 7, true, false)
		var start_angle: float = -PI/4
		var increment_angle: float = PI/16
		var sweep_range: int = 8
		sweep_vectors = radial_vector_sweep(ship_query, target_query, start_angle, increment_angle, sweep_range)
	
	# raycast_sweep() returns an empty array if sweep_vectors is empty
	var valid_paths: Array[Vector2] = raycast_sweep(sweep_vectors, target_position)
	if not sweep_vectors.is_empty() and valid_paths.is_empty():
		valid_paths = raycast_sweep(sweep_vectors, global_position)
	
	if intermediate_pathing == false and not valid_paths.is_empty() and not ShipNavigationAgent.is_navigation_finished():
		intermediate_pathing = true
		ShipNavigationAgent.set_target_position(pick_path(valid_paths))
		final_target_position = target_position
		NavigationTimer.start()
	# Do this after finishing the intermediate pathing.
	elif intermediate_pathing == true and ShipNavigationAgent.is_navigation_finished():
		target_position = final_target_position
		ShipNavigationAgent.set_target_position(target_position)
		intermediate_pathing = false
	
	# Normal Pathing
	if not ShipNavigationAgent.is_navigation_finished():
		var next_path_position: Vector2 = ShipNavigationAgent.get_next_path_position()
		var direction_to_path: Vector2 = global_position.direction_to(next_path_position)
		velocity = direction_to_path * movement_delta
		
		var normalize_velocity: Vector2 = linear_velocity / velocity
		var ease_x: float = linear_velocity.x * ease(normalize_velocity.x, ship_stats.acceleration)
		var ease_y: float = linear_velocity.y * ease(normalize_velocity.y, ship_stats.acceleration)
		velocity += Vector2(ease_x, ease_y)
		
		var transform_look_at: Transform2D = transform.looking_at(next_path_position)
		transform = transform.interpolate_with(transform_look_at, delta * ship_stats.turn_rate)
	
	acceleration += velocity - linear_velocity
	linear_velocity += lerp(-linear_velocity, Vector2.ZERO, delta * ship_stats.deceleration)
	
	if acceleration.abs().floor() != Vector2.ZERO and sleeping:
		sleeping = false

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var force: Vector2 = acceleration
	if force.abs().floor() != Vector2.ZERO and not manual_control:
		apply_central_force(force)
	
	if manual_control:
		apply_torque(rotate_angle)
		apply_force(force)
	
	# use apply_impulse for one-shot calculations for collisions
	# its time-independent hence why its a one-shot

func ease_velocity(velocity: Vector2) -> Vector2:
	var new_velocity: Vector2 = Vector2.ZERO
	var normalize_velocity_x: float = linear_velocity.x / velocity.x
	var normalize_velocity_y: float = linear_velocity.y / velocity.y
	if velocity.x == 0.0:
		normalize_velocity_x = 0.0
	if velocity.y == 0.0:
		normalize_velocity_y = 0.0
	new_velocity.x = linear_velocity.x * ease(normalize_velocity_x, ship_stats.acceleration)
	new_velocity.y = linear_velocity.y * ease(normalize_velocity_y, ship_stats.acceleration)
	return new_velocity

# Feel like this is obvious if you need to write a comment to make more sense of it be my guest.
func collision_raycast(from: Vector2, to: Vector2, collision_bitmask: int, test_area: bool, test_body: bool) -> Dictionary:
	var results: Dictionary = {}
	# If there are bizarre pathing issues, this may be part of the reason why. Review _physics_process for
	# any potential edge case issues.
	#if intermediate_pathing == false and ShipNavigationAgent.is_navigation_finished():
	#	return results
	
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to, collision_bitmask, [self])
	query.collide_with_areas = test_area
	query.collide_with_bodies = test_body
	results = space_state.intersect_ray(query)
	return results

# Translating the center of a circle with the target position.
func translate_radial_vector(direction: Vector2, radius: float) -> Vector2:
	var translation: Vector2 = Vector2(direction.x * radius, direction.y * radius)
	var new_vector: Vector2 = Vector2(target_position.x + translation.x, target_position.y + translation.y)
	return new_vector

# idk how to explain this it does a radial vector sweep there literally exists a function called Sweep2D or whatever
# that i didnt use because it didnt work well with area2d's and this approach does
func radial_vector_sweep(ship_query: Dictionary, target_query: Dictionary, start_angle: float, increment_angle: float, sweep_range: int) -> Array[Vector2]:
	var sweep_vectors: Array[Vector2] = []
	if ship_query.is_empty() or target_query.is_empty():
		return sweep_vectors
	
	#collider: The colliding object.
	#collider_id: The colliding object's ID.
	#normal: The object's surface normal at the intersection point, or Vector2(0, 0) if the ray starts inside the shape and PhysicsRayQueryParameters2D.hit_from_inside is true.
	#position: The intersection point.
	#rid: The intersecting object's RID.
	#shape: The shape index of the colliding shape.
	
	# flip the direction of the raycast normal to make it face the collider
	var target_direction: Vector2 = -1*target_query["normal"]
	
	# find the distance from the target position to the intersection
	var intersection_position: Vector2 = ship_query["position"]
	var sweep_radius: float = target_position.distance_to(intersection_position)
	
	# get the radial vectors using the sweep radius
	var new_sweep_direction: Vector2 = target_direction.rotated(start_angle)
	for i in range(sweep_range): # no, "i" does nothing here, rewrite this approach if bothers you
		new_sweep_direction = new_sweep_direction.rotated(increment_angle)
		sweep_vectors.push_back(translate_radial_vector(new_sweep_direction, sweep_radius))
	
	return sweep_vectors

# Do a raycast from to local target position to the vector position. Should return valid paths.
func raycast_sweep(sweep_vectors: Array[Vector2], local_target_pos: Vector2) -> Array[Vector2]:
	var valid_paths: Array[Vector2] = []
	if sweep_vectors.is_empty():
		return valid_paths
	 
	var skip_next_entry: bool = false
	for vector in sweep_vectors:
		if skip_next_entry:
			# hokey workaround for removing paths around an invalid path that are likely to cause collisions
			skip_next_entry = false
			continue
		
		var raycast_results: Dictionary = collision_raycast(local_target_pos, vector, 7, true, false)
		if raycast_results.is_empty():
			valid_paths.push_back(vector)
		else:
			valid_paths.pop_back() # remove previous valid entry
			skip_next_entry = true
	
	return valid_paths

func pick_path(valid_paths: Array[Vector2]) -> Vector2:
	var valid_path_range: int = valid_paths.size() - 1
	var random_entry: int = randi_range(0, valid_path_range)
	return valid_paths[random_entry]

func _on_NavigationTimer_timeout() -> void:
	if ShipNavigationAgent.is_navigation_finished():
		NavigationTimer.stop()
		return
	
	var target_query: Dictionary = {}
	var ship_query: Dictionary = {}
	ship_query = collision_raycast(global_position, target_position, 7, true, false)
	var sweep_vectors: Array[Vector2] = []
	if not ship_query.is_empty():
		var collider_instance: Node = instance_from_id(ship_query["collider_id"])
		var collider_center: Vector2 = collider_instance.global_position
		target_query = collision_raycast(target_position, collider_center, 7, true, false)
		var start_angle: float = -PI/8
		var increment_angle: float = PI/64
		var sweep_range: int = 16
		sweep_vectors = radial_vector_sweep(ship_query, target_query, start_angle, increment_angle, sweep_range)
	
	if sweep_vectors.is_empty():
		ShipNavigationAgent.set_target_position(target_position)
		return
	
	var valid_paths: Array[Vector2] = raycast_sweep(sweep_vectors, target_position)
	if not ship_query.is_empty() and valid_paths.is_empty():
		valid_paths = raycast_sweep(sweep_vectors, global_position)
	elif not valid_paths.is_empty():
		ShipNavigationAgent.set_target_position(pick_path(valid_paths))

# if this fails to fix the problem with avoidance, oh well
# somebody else can code this because im pretty much burnt on this stuff
func _on_ShipNavigationAgent_velocity_computed(safe_velocity):
	if safe_velocity != Vector2.ZERO:
		linear_velocity = safe_velocity
