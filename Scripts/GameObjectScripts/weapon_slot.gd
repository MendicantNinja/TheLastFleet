extends Node2D
class_name WeaponSlot

# Nodes
@onready var weapon_mount_image: Sprite2D = $WeaponNode/WeaponMountSprite
@onready var weapon_image: Sprite2D = $WeaponNode/WeaponMountSprite/WeaponSprite
@onready var effective_range_shape: CollisionShape2D = $EffectiveRange/EffectiveRangeShape
@onready var effective_range: Area2D = $EffectiveRange
@onready var weapon_node: Node2D = $WeaponNode
@onready var rate_of_fire_timer: Timer = $ROFTimer
# Important Stuff
#@export var assigned_ship: Ship

@export var weapon: Weapon:
	set(value):
		weapon = value
		if weapon_image != null:
			weapon_image.texture = value.image
		else:
			return
@export var weapon_mount: WeaponMount:
	set(value):
		weapon_mount = value
		if weapon_mount_image != null:
			weapon_mount_image.texture = value.image
		else:
			return

# Bools and toggles
@onready var ready_to_fire: bool = true # This is that little green bar in Starsector for missiles and burst weapons that reload. Not important yet.
var manual_aim: bool = false
var display_aim: bool = false
var auto_aim: bool = false
var auto_fire: bool = false
var can_look_at: bool = false
var can_fire: bool = false
var flux_overload: bool = false
var is_friendly: bool = false
var target_engaged: bool = false
var manual_camera: bool = false

var range_display_color: Color = Color.SNOW
var range_display_count: int = 64
var range_display_width: float = 1.0

var available_targets: Dictionary = {}
var killcast: RayCast2D = null
var arc_in_radians: float = 0.0
var target_ship_position: Vector2 = Vector2.ZERO
var last_valid_position: Vector2 = Vector2.ZERO
var default_direction: Transform2D
var target_unit: RID = RID()
var current_target_id: RID = RID()
var owner_rid: RID = RID()

signal weapon_slot_fired(flux)
signal remove_manual_camera(camera)
signal target_in_range(value)
signal new_threats(targets)
signal update_threats(targets)

# Called to spew forth a --> SINGLE <-- projectile scene from the given Weapon in the WeaponSlot. Firing speed is tied to delta in ship.gd.
func fire(ship_id: int) -> void:
	if flux_overload or not can_fire:
		return
	if weapon == data.weapon_dictionary.get(data.weapon_enum.EMPTY):
		return
	if manual_aim and not can_look_at:
		return
	
	if weapon.flux_per_shot > 0.0:
		weapon_slot_fired.emit(weapon.flux_per_shot)
	elif weapon.flux_per_second > 0.0:
		weapon_slot_fired.emit(weapon.flux_per_second)
	
	var projectile: Area2D = weapon.create_projectile().instantiate()
	projectile.global_transform = weapon_node.global_transform
	projectile.assign_stats(weapon, ship_id)
	get_tree().root.add_child(projectile)
	
	can_fire = false
	rate_of_fire_timer.start()

# Only called by ship_stats.initialize() or on implicit new in the generic ship scene. Never again.
func _init(p_weapon_mount: WeaponMount = data.weapon_mount_dictionary.get(data.weapon_mount_enum.SMALL_BALLISTIC), p_weapon: Weapon = data.weapon_dictionary.get(data.weapon_enum.EMPTY)):
	weapon_mount = p_weapon_mount
	weapon = p_weapon

func _draw() -> void:
	if not manual_aim and not display_aim:
		range_display_color = Color(range_display_color, 0.4)
		return
	
	var divisor: float = 100.0
	var subdivisions: int = floor(effective_range_shape.shape.radius / divisor)
	var start_angle: float = deg_to_rad((-weapon_mount.firing_arc / 2))
	var end_angle: float = deg_to_rad((weapon_mount.firing_arc / 2))
	var start_transform: Vector2 = default_direction.x.rotated(start_angle)
	var end_transform: Vector2 = default_direction.x.rotated(end_angle)
	start_angle = start_transform.angle()
	end_angle = end_transform.angle()
	for i in range(0, subdivisions):
		draw_arc(weapon_node.transform.origin, (i + 1) * divisor, start_angle, end_angle, range_display_count, range_display_color, range_display_width, true)

func _ready():
	weapon_mount_image.texture = weapon_mount.image
	weapon_image.texture = weapon.image
	z_index = 2
	
	rate_of_fire_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	can_fire = true
	rate_of_fire_timer.timeout.connect(_on_ROF_timeout)
	
	default_direction = weapon_node.transform
	arc_in_radians = deg_to_rad(weapon_mount.firing_arc / 2.0)
	
	effective_range.body_entered.connect(_on_EffectiveRange_entered)
	effective_range.body_exited.connect(_on_EffectiveRange_exited)

func set_weapon_slot(p_weapon: Weapon) -> void:
	weapon = p_weapon
	
	var new_shape: Shape2D = CircleShape2D.new()
	new_shape.radius = weapon.range
	effective_range_shape.shape = new_shape
	
	var interval_in_seconds: float = 1.0 / weapon.fire_rate
	rate_of_fire_timer.wait_time = interval_in_seconds

func detection_parameters(mask: int, friendly_value: bool, owner_value: RID) -> void:
	effective_range.collision_mask = mask
	is_friendly = friendly_value
	owner_rid = owner_value
	if not is_friendly:
		auto_aim = true
	set_weapon_size_and_color()

func set_auto_fire(fire_value: bool) -> void:
	auto_fire = fire_value
	if fire_value == false:
		manual_aim = true

func set_auto_aim(aim_value: bool) -> void:
	auto_aim = aim_value
	if aim_value == false:
		manual_aim = true

# Not my brightest programming decision but whatever
# this exists mostly for manual control sake, not for AI sake.
func toggle_auto_aim() -> void:
	if auto_aim == false:
		auto_aim = true
		manual_aim = false
	else:
		auto_aim = false
		manual_aim = true

func toggle_auto_fire() -> void:
	if auto_fire == false:
		auto_fire = true
		manual_aim = false
	else:
		auto_fire = false
		manual_aim = true

func set_manual_aim(aim_value: bool) -> void:
	if aim_value == true:
		manual_aim = true
		auto_fire = false
		auto_aim = false
	elif aim_value == false:
		manual_aim = false
		auto_aim = true
		auto_fire = true
	queue_redraw()

func update_flux_overload(flux_state: bool) -> void:
	flux_overload = flux_state

# Assigns the RID of the ship the player targets to the variable target_unit.
func set_target_unit(unit) -> void:
	target_unit = unit.get_rid()
	if not available_targets.has(target_unit):
		target_in_range.emit(false)

func set_weapon_size_and_color():
	if is_friendly:
		weapon_mount_image.modulate = settings.player_color
	elif not is_friendly:
		weapon_mount_image.modulate = get_parent().self_modulate
	#weapon_image.self_modulate = settings.player_color
	match weapon_mount.weapon_mount_size:
		data.size_enum.SMALL:
			weapon_mount_image.scale = Vector2(.2, .2)#/assigned_ship.scale # Important to scale weapon slots so that the size is constant.
		data.size_enum.MEDIUM:
			weapon_mount_image.scale = Vector2(.4, .4)#/assigned_ship.scale
		data.size_enum.LARGE:
			weapon_mount_image.scale = Vector2(.7, .7)#/assigned_ship.scale
		data.size_enum.SPINAL:
			weapon_mount_image.scale = Vector2(1, 1)#/assigned_ship.scale
		_:
			print("Unknown weapon size.")
	
	#match weapon_mount.weapon_mount_type:
		#data.weapon_mount_type_enum.BALLISTIC:
			#weapon_mount_image.self_modulate = Color8(255, 100, 20, 255)
		#data.weapon_mount_type_enum.ENERGY:
			#weapon_mount_image.self_modulate = Color8(0, 212, 255, 255)
		#data.weapon_mount_type_enum.HYBRID:
			#weapon_mount_image.self_modulate = Color8(0, 255, 123, 255)
		#data.weapon_mount_type_enum.MISSILE:
			#weapon_mount_image.self_modulate = Color8(255, 51, 0, 255)
		#data.weapon_mount_type_enum.UNIVERSAL:
			#weapon_mount_image.self_modulate = Color8(255, 198, 184, 255)
		#_:
			#print("Unknown weapon type.")

func toggle_display_aim(toggle: bool) -> void:
	display_aim = toggle
	queue_redraw()

func _on_ROF_timeout() -> void:
	can_fire = true

# Creates the context for a weapon's given situation.
func _on_EffectiveRange_entered(body) -> void:
	if body.get_rid() == owner_rid: 
		return # ignore any overlap with other weapon slots
	elif is_friendly == body.is_friendly:
		return # ignore friendly ships if its a player (true == true) and vice versa for enemy ships (false == false)
	elif body.get_collision_layer_value(2) or body.get_collision_layer_value(4): 
		return # ignore obstacle and projectile layers, respectively
	
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_transform.origin, body.global_position, 7, [self, owner_rid])
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var raycast_query: Dictionary = space_state.intersect_ray(query)
	if raycast_query.is_empty():
		return # ignore if nothing is detected by the query
	if raycast_query["collider"].get_collision_layer_value(2):
		return # ignore if an obstacle is in the way
	
	if not killcast:
		killcast = create_killcast()
		add_child(killcast)

	var ship_id = body.get_rid()
	if killcast and target_unit == ship_id:
		killcast.target_position = to_local(body.global_position)
		target_in_range.emit(true)
		target_engaged = true
		killcast.force_raycast_update()
	elif killcast:
		killcast.target_position = to_local(body.global_position)
		current_target_id = ship_id
		killcast.force_raycast_update()
	
	if not available_targets.has(ship_id):
		available_targets[ship_id] = body
		new_threats.emit(available_targets.values())

# Flips bools, removes references, and attempts to find other targets, all based off different ships leaving
# the effective range and the current combat situation.
func _on_EffectiveRange_exited(body) -> void:
	var ship_id: RID = body.get_rid()
	available_targets.erase(ship_id)
	
	update_threats.emit(available_targets.values())

	if killcast and available_targets.is_empty():
		killcast.queue_free()
		killcast = null

# Instance a new raycast anytime an "enemy" is within the generalized effective range.
func create_killcast() -> RayCast2D:
	var new_killcast: RayCast2D = RayCast2D.new()
	new_killcast.collide_with_bodies = true
	new_killcast.collide_with_areas = false
	new_killcast.collision_mask = 7
	return new_killcast

# If a weapon is not capable of firing on an existing target but more are around it,
# this will try to find the nearest available target if it can. This function is
# called every physics frame IF it still cannot find a valid target.
func acquire_new_target() -> void:
	if available_targets.is_empty():
		return
	var ship_ids: Array = available_targets.keys()
	var taq_range: int = ship_ids.size() - 1
	var rand_key_number: int = randi_range(0, taq_range)
	var new_target_id: RID = ship_ids[rand_key_number]
	var ship_instance: Ship = available_targets[new_target_id]
	killcast.target_position = to_local(ship_instance.global_position)
	killcast.force_raycast_update()

# Returns a new transform to face the weapon in the direction of an "enemy" ship.
# Returns the default transform which is the default direction it should face given nothing
# is actually within its effective range.
func face_weapon(target_position: Vector2) -> Transform2D:
	var target_transform: Transform2D = weapon_node.transform.looking_at(target_position)
	var scale_transform: Vector2 = weapon_node.scale
	target_transform = target_transform.scaled(scale_transform)
	var dot_product: float = default_direction.x.dot(target_transform.x)
	var angle_to_node: float = acos(dot_product)
	
	var direction_to: Vector2 = weapon_node.transform.x.direction_to(target_position)
	
	can_look_at = true
	if angle_to_node > arc_in_radians or dot_product < 0:
		can_look_at = false
	
	if not can_look_at and manual_aim:
		target_transform = weapon_node.transform.looking_at(last_valid_position)
	elif not can_look_at and not manual_aim:
		return default_direction
	elif can_look_at:
		last_valid_position = target_position
	
	return target_transform

func _physics_process(delta) -> void:
	if flux_overload:
		return
	if manual_aim:
		var mouse_position = to_local(get_global_mouse_position())
		var face_direction: Transform2D = face_weapon(mouse_position)
		weapon_node.transform = weapon_node.transform.interpolate_with(face_direction, delta * weapon.turn_rate)
	if killcast:
		update_killcast(delta)

# this function has two purposes:
# A) updates the raycast every physics frame to track a ship's current position
# B) checks to see if a ship the player targets is within the effective range of the weapon
func update_killcast(delta) -> void:
	if available_targets.is_empty():
		killcast.queue_free()
		return
	var collider = killcast.get_collider()
	if not collider is Ship: # Do not shoot at obstacles
		can_look_at = false
		return
	if collider is Ship and is_friendly == collider.is_friendly: # Do not shoot at friendly ships
		can_look_at = false
		return

	current_target_id = collider.get_rid()
	var ship_position: Vector2 = to_local(collider.global_position)
	if target_engaged and current_target_id != target_unit:
		if not available_targets.has(target_unit):
			return
		var target_position: Vector2 = to_local(available_targets[target_unit].global_position)
		ship_position = target_position
		current_target_id = target_unit
		killcast.target_position = ship_position
		killcast.force_raycast_update()
		return

	killcast.target_position = ship_position
	
	if (auto_aim or auto_fire):
		var face_direction: Transform2D = face_weapon(killcast.target_position)
		weapon_node.transform = weapon_node.transform.interpolate_with(face_direction, delta * weapon.turn_rate)
	
	if can_look_at and can_fire:
		fire(owner_rid.get_id())
	
	if can_look_at == false and available_targets.size() > 1:
		acquire_new_target()
