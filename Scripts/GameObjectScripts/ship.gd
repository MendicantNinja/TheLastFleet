extends RigidBody2D
class_name Ship

@onready var ShipNavigationAgent = $ShipNavigationAgent
@onready var NavigationTimer = $NavigationTimer
@onready var ShipCollisionShape = $Area2D/CollisionShape2D
@onready var ShipSprite = $ShipSprite

@onready var all_weapons: Array[WeaponSlot]

#Temporary variables
# Should group weapon slots in the near future instead of this, even though call_group() broke in 4.3 stable.
# Might mean something silly like another Node2D that functionally groups
# all weapon slots as child nodes. We could then call that node "WeaponSystem" or whatever.
@onready var WeaponSlot0 = $WeaponSlot0
@onready var WeaponSlot1 = $WeaponSlot1

var ship_stats: ShipStats
var speed: float = 0.0
var hull_integrity: float = 0.0

# Used for targeting and weapons.

# Used for intermediate pathing around dynamic agents
var final_target_position: Vector2 = Vector2.ZERO
var intermediate_pathing: bool = false
var acceleration: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var movement_delta: float = 0.0
var ship_select: bool = false

func _ready() -> void:
	ship_stats = ShipStats.new(data.ship_type_enum.TEST)
	speed = ship_stats.top_speed
	
	var ship_hull = ship_stats.ship_hull
	ShipSprite.texture = ship_hull.ship_sprite
	
	$ShipSprite.self_modulate = settings.player_color
	
	#Assigns weapon slots based on what's in the ship scene.
	for child in get_children():
		if child is WeaponSlot:
			all_weapons.append(child)
	for i in range(all_weapons.size()):
		# Temporary hack to test weapons so that the mounts aren't empty.
		# MENDICANT ONLY: all_weapons[i]=ship_stats.weapon_slots[i] make sure that ship stats 
		# assigns the child nodes like WeaponMountSprite and WeaponSprite or else they will be 
		# null and cause errors.
		all_weapons[i].weapon = data.weapon_dictionary.get(data.weapon_enum.RAILGUN)
		# In the future, weapons will automatically be assigned from the already existing weapons in 
		# ship_stats during fleet deployment. Unfortunately refitting + save/load isn't in yet so 
		# everything is a railgun.

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
		if event.pressed and event.button_mask == MOUSE_BUTTON_MASK_LEFT and ship_select:
			intermediate_pathing = false
			target_position = get_global_mouse_position()
			ShipNavigationAgent.set_target_position(target_position)  # move selected ship at event position
		elif event.pressed and event.button_mask == MOUSE_BUTTON_MASK_RIGHT and ship_select:
			ship_select = false # deselect ship by right clicking anywhere
	elif event is InputEventKey:
		if (event.keycode == KEY_F and event.is_pressed()):
			fire_weapon_slot(all_weapons[0])
		if (event.keycode == KEY_Q and event.is_pressed()):
			fire_weapon_system(all_weapons)
	elif event is InputEventMouseMotion:
		if ship_select:
			face_weapons(all_weapons, get_global_mouse_position())

# When the player interacts with the ship via mouse.
func _on_input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_mask == MOUSE_BUTTON_MASK_LEFT and not ship_select:
			ship_select = true # select ship
		elif event.pressed and event.button_mask == MOUSE_BUTTON_MASK_LEFT and ship_select:
			ship_select = false # deselect ship

#oooooo   oooooo     oooo oooooooooooo       .o.       ooooooooo.     .oooooo.   ooooo      ooo  .oooooo..o 
 #`888.    `888.     .8'  `888'     `8      .888.      `888   `Y88.  d8P'  `Y8b  `888b.     `8' d8P'    `Y8 
  #`888.   .8888.   .8'    888             .8"888.      888   .d88' 888      888  8 `88b.    8  Y88bo.      
   #`888  .8'`888. .8'     888oooo8       .8' `888.     888ooo88P'  888      888  8   `88b.  8   `"Y8888o.  
	#`888.8'  `888.8'      888    "      .88ooo8888.    888         888      888  8     `88b.8       `"Y88b 
	 #`888'    `888'       888       o  .8'     `888.   888         `88b    d88'  8       `888  oo     .d8P 
	  #`8'      `8'       o888ooooood8 o88o     o8888o o888o         `Y8bood8P'  o8o        `8  8""88888P'  

func fire_weapon_system (weapon_system: Array[WeaponSlot]) -> void:
	for weapon_slot in weapon_system:
		fire_weapon_slot(weapon_slot)

func fire_weapon_slot(weapon_slot: WeaponSlot ) -> void:
	weapon_slot.fire()

func face_weapons(weapon_system: Array[WeaponSlot], mouse_position: Vector2) -> void:
	for weapon_slot in weapon_system:
		var weapon_transform: Transform2D = weapon_slot.global_transform
		var weapon_scale: Vector2 = weapon_slot.scale
		var transform_look_at: Transform2D = weapon_transform.looking_at(mouse_position)
		var local_origin: Vector2 = weapon_slot.transform.origin
		transform_look_at.origin = local_origin
		transform_look_at = transform_look_at.scaled_local(weapon_scale)
		weapon_slot.transform = weapon_slot.transform.interpolate_with(transform_look_at, ship_stats.turn_rate)

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
	
	var ship_origin: Vector2 = transform.get_origin()
	var velocity = Vector2.ZERO
	movement_delta = speed * delta
	
	var ship_query: Dictionary = {}
	ship_query = collision_raycast(global_position, target_position, 7)
	
	var sweep_vectors: Array[Vector2] = []
	if not ship_query.is_empty():
		var collider_instance: Node = instance_from_id(ship_query["collider_id"])
		var collider_center: Vector2 = collider_instance.global_position
		var target_query: Dictionary = collision_raycast(target_position, collider_center, 7)
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
	
	var motion_cast_result: PackedFloat32Array = []
	# Normal Pathing
	if not ShipNavigationAgent.is_navigation_finished():
		ShipNavigationAgent.set_max_speed(movement_delta)
		var next_path_position: Vector2 = ShipNavigationAgent.get_next_path_position()
		var direction_to_path: Vector2 = ship_origin.direction_to(next_path_position)
		velocity = direction_to_path * movement_delta
		
		var normalize_velocity: Vector2 = linear_velocity / velocity
		var ease_x: float = linear_velocity.x * ease(normalize_velocity.x, ship_stats.acceleration)
		var ease_y: float = linear_velocity.y * ease(normalize_velocity.y, ship_stats.acceleration)
		velocity += Vector2(ease_x, ease_y)
		
		var transform_look_at: Transform2D = transform.looking_at(next_path_position)
		transform = transform.interpolate_with(transform_look_at, delta * ship_stats.turn_rate)
	
	acceleration += velocity - linear_velocity
	# decrease linear velocity to converge acceleration to zero, thus
	# converging force to zero
	linear_velocity += lerp(-linear_velocity, Vector2.ZERO, delta * ship_stats.deceleration)
	# kind of infuriating i cant move this to _integrate_forces (like i should) but im not really
	# interested in touching this code anymore

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var force: Vector2 = acceleration
	if force.abs().floor() != Vector2.ZERO:
		apply_central_force(force)
	
	# use apply_impulse for one-shot calculations for collisions
	# its time-independent hence why its a one-shot

# Feel like this is obvious if you need to write a comment to make more sense of it be my guest.
func collision_raycast(from: Vector2, to: Vector2, collision_bitmask: int) -> Dictionary:
	var results: Dictionary = {}
	if intermediate_pathing == false and ShipNavigationAgent.is_navigation_finished():
		return results
	
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to, collision_bitmask, [self])
	query.collide_with_areas = true
	query.collide_with_bodies = false
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
		
		var raycast_results: Dictionary = collision_raycast(local_target_pos, vector, 7)
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
	ship_query = collision_raycast(global_position, target_position, 7)
	var sweep_vectors: Array[Vector2] = []
	if not ship_query.is_empty():
		var collider_instance: Node = instance_from_id(ship_query["collider_id"])
		var collider_center: Vector2 = collider_instance.global_position
		target_query = collision_raycast(target_position, collider_center, 7)
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
