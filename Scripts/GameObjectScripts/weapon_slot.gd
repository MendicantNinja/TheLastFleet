extends Node2D
class_name WeaponSlot


# Nodes
@onready var WeaponMountImage: Sprite2D = $WeaponNode/WeaponMountSprite
@onready var WeaponImage: Sprite2D = $WeaponNode/WeaponMountSprite/WeaponSprite
@onready var EffectiveRangeShape: CollisionShape2D = $EffectiveRange/EffectiveRangeShape
@onready var EffectiveRange: Area2D = $EffectiveRange
@onready var WeaponNode: Node2D = $WeaponNode
@onready var ROFTimer: Timer = $ROFTimer
@onready var SoftlockTimer = $SoftlockTimer
@onready var ContinuousFluxTimer = $ContinuousFluxTimer
# Important Stuff
@export var weapon_system_group: int = -1

@export var weapon: Weapon:
	set(value):
		if value == null:
			return
		weapon = value
		if WeaponImage != null:
			WeaponImage.texture = value.image
		else:
			return
@export var weapon_mount: WeaponMount:
	set(value):
		weapon_mount = value
		if WeaponMountImage != null:
			WeaponMountImage.texture = value.image
		else:
			return

var projectile_sprite: Texture2D

# Bools and toggles
@onready var ready_to_fire: bool = true # This is that little green bar in Starsector for missiles and burst weapons that reload. Not important yet.
var manual_aim: bool = false
var display_aim: bool = false
var auto_aim: bool = false
var auto_fire: bool = false
var can_look_at: bool = false
var timer_fire: bool = false
var can_fire: bool = false
var flux_overload: bool = false: 
	set(value):
		flux_overload = value
		if flux_overload == true:
			stop_continuous_beam()
var is_friendly: bool = false
var target_engaged: bool = false
var manual_camera: bool = false
var AI_enabled: bool = false:
	set(value):
		AI_enabled = value

var ai_debug: bool = false

var range_display_color: Color = Color.SNOW
var range_display_count: int = 64
var range_display_width: float = 1.0
var softlock_wait: float = 2.0
var arc_in_radians: float = 0.0
var default_direction: Transform2D

var available_targets: Dictionary = {}
var weighted_targets: Dictionary = {}: # key prob pair body
	set(value):
		weighted_targets = value

var primary_target: RID = RID()
var current_target: RID = RID()
var owner_rid: RID = RID()
var killcast: RayCast2D = null
var last_valid_position: Vector2 = Vector2.ZERO
var target_unit: RID = RID()
var current_target_id: RID = RID()
var shield_rid: RID = RID()

# Special Beam Logic
var current_beam: Projectile = null
var projectile_inst: Projectile = null

signal weapon_slot_fired(flux)
signal target_in_range(value)
signal new_threats(targets)
signal threat_exited(targets)

# Called to spew forth a --> SINGLE <-- projectile (or beam) scene from the given Weapon in the WeaponSlot.
func fire(ship_id: int) -> void:
	if flux_overload == true or timer_fire == false or current_beam != null:
		return
	if weapon == data.weapon_dictionary.get(data.weapon_enum.EMPTY):
		return
	if manual_aim and can_look_at == false:
		return
	
	if weapon.is_beam == false and weapon.is_continuous == false:
		if weapon.flux_per_shot > 0.0:
			weapon_slot_fired.emit(weapon.flux_per_shot)
	
	var projectile: Area2D = weapon.create_projectile().instantiate() # Do not statically type, most projectiles are Area2D's, but beams are Line2D's
	projectile.global_transform = WeaponNode.global_transform
	projectile.assign_stats(weapon, owner_rid, shield_rid, is_friendly)
	
	if projectile.is_beam == true:
		current_beam = projectile
		if current_beam.is_continuous == false:
			current_beam.projectile_freed.connect(func():
				current_beam = null  # Clear reference after projectile is freed
			)
		else:
			ContinuousFluxTimer.start() # Flux per second for continuous beams.
	get_tree().current_scene.add_child(projectile)
	globals.play_audio_pitched(weapon.firing_sound, self.global_position)
	
	if projectile.is_continuous == false: # We don't want a rate of fire timer for a continuous beam.
		timer_fire = false
		ROFTimer.start()

func stop_continuous_beam() -> void:
	ContinuousFluxTimer.stop()
	if current_beam != null:
		current_beam.queue_free()
		current_beam = null 

# Only called by ship_stats.initialize() or on implicit new in the generic ship scene. Never again.
func _init(p_weapon_mount: WeaponMount = data.weapon_mount_dictionary.get(data.weapon_mount_enum.SMALL_BALLISTIC), p_weapon: Weapon = data.weapon_dictionary.get(data.weapon_enum.EMPTY)):
	weapon_mount = p_weapon_mount
	weapon = p_weapon
	
@warning_ignore("integer_division")
func _draw() -> void:
	if not manual_aim and not display_aim:
		range_display_color = Color(range_display_color, 0.4)
		return
	
	var divisor: float = weapon.range # Change to effective range later from shipmods? Firing arcs need a bit of a rework sometime.
	var subdivisions: int = floor(EffectiveRangeShape.shape.radius / divisor)
	var start_angle: float = deg_to_rad((-weapon_mount.firing_arc / 2))
	var end_angle: float = deg_to_rad((weapon_mount.firing_arc / 2))
	var start_transform: Vector2 = default_direction.x.rotated(start_angle)
	var end_transform: Vector2 = default_direction.x.rotated(end_angle)
	start_angle = start_transform.angle()
	end_angle = end_transform.angle()
	if display_aim == true:
		for i in range(0, subdivisions):
			draw_arc(WeaponNode.transform.origin, (i + 1) * divisor, start_angle, end_angle, range_display_count, range_display_color, range_display_width, true)

# Warning! Use set_weapon_slot() below rather than ready if the property 
# you are messing with depends on the type of weapon.
# The actual weapon used in combat is not assigned in ready, but in set_weapon_slot.
#func _ready():
	#pass

func set_weapon_slot(p_weapon_slot: WeaponSlot) -> void:
	weapon_system_group = 0 # Index of 0 = weapon system 1
	
	WeaponMountImage.texture = weapon_mount.image
	WeaponImage.texture = weapon.image
	
	killcast = create_killcast()
	add_child(killcast)
	SoftlockTimer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	ROFTimer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	SoftlockTimer.wait_time = 10.0
	timer_fire = true
	can_fire = false
	ROFTimer.timeout.connect(_on_ROF_timeout)
	SoftlockTimer.timeout.connect(_on_Softlock_timeout)
	default_direction = WeaponNode.transform
	arc_in_radians = deg_to_rad(weapon_mount.firing_arc / 2.0)
	
	# Move this to set_weapon_slot below if this is giving trouble. See method comment above.
	EffectiveRange.body_entered.connect(_on_EffectiveRange_entered)
	EffectiveRange.body_exited.connect(_on_EffectiveRange_exited)
	
	# Give everything railguns in dev mode for empty weapons
	if settings.dev_mode == true and p_weapon_slot.weapon == data.weapon_dictionary.get(data.weapon_enum.EMPTY):
		weapon = data.weapon_dictionary.get(data.weapon_enum.RAILGUN)
		
		var new_shape: Shape2D = CircleShape2D.new()
		new_shape.radius = weapon.range
		EffectiveRangeShape.shape = new_shape
		
		var interval_in_seconds: float = 1.0 / weapon.fire_rate
		ROFTimer.wait_time = interval_in_seconds
	else:
		weapon = p_weapon_slot.weapon
		weapon_system_group = p_weapon_slot.weapon_system_group
		
		var new_shape: Shape2D = CircleShape2D.new()
		new_shape.radius = p_weapon_slot.weapon.range
		EffectiveRangeShape.shape = new_shape
		
		var interval_in_seconds: float = 1.0 / p_weapon_slot.weapon.fire_rate
		ROFTimer.wait_time = interval_in_seconds
	if weapon.is_continuous == true:
		ContinuousFluxTimer.timeout.connect(on_continuous_flux_timer_timeout)
	
	projectile_inst = weapon.create_projectile().instantiate()
	add_child(projectile_inst)
	projectile_sprite = projectile_inst.Sprite.texture
	pass

func on_continuous_flux_timer_timeout() -> void:
	emit_signal("weapon_slot_fired", weapon.flux_per_shot*.05) 
	# Flux per shot == flux per second in the case of continuous beams.

func detection_parameters(mask: int, friendly_value: bool, owner_value: RID, p_shield_rid: RID) -> void:
	EffectiveRange.collision_mask = mask
	is_friendly = friendly_value
	owner_rid = owner_value
	shield_rid = p_shield_rid
	auto_aim = true
	auto_fire = true
	#set_weapon_size_and_color()

func set_auto_fire(fire_value: bool) -> void:
	auto_fire = fire_value
	if fire_value == false:
		manual_aim = true
		if weapon.is_continuous == true:
			stop_continuous_beam()

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

# Assigns the RID of the ship the player targets to the variable primary_target.
func set_primary_target(unit) -> void:
	if AI_enabled == true and unit == null:
		primary_target = RID()
		acquire_new_target_AI()
	elif AI_enabled == true and unit != null:
		primary_target = unit.get_rid()
	elif unit == null and available_targets.size() > 0:
		acquire_new_target()
	elif unit == null:
		primary_target = RID()
	else:
		primary_target = unit.get_rid()

func toggle_display_aim(toggle: bool) -> void:
	display_aim = toggle
	queue_redraw()

# Instance a new raycast anytime an "enemy" is within the generalized effective range.
func create_killcast() -> RayCast2D:
	var new_killcast: RayCast2D = RayCast2D.new()
	new_killcast.collide_with_bodies = true
	new_killcast.collide_with_areas = false
	new_killcast.collision_mask = 15
	new_killcast.enabled = true
	return new_killcast

# Returns a new transform to face the weapon in the direction of an "enemy" ship.
# Returns the default transform which is the default direction it should face given nothing
# is actually within its effective range.
func face_weapon(target_position: Vector2) -> Transform2D:
	var target_transform: Transform2D = WeaponNode.transform.looking_at(target_position)
	var scale_transform: Vector2 = WeaponNode.scale
	target_transform = target_transform.scaled(scale_transform)
	var dot_product: float = default_direction.x.dot(target_transform.x)
	var angle_to_node: float = acos(dot_product)
	
	can_look_at = true
	if angle_to_node > arc_in_radians or dot_product < 0:
		can_look_at = false
	
	if not can_look_at and manual_aim:
		target_transform = WeaponNode.transform.looking_at(last_valid_position)
	elif not can_look_at and not manual_aim:
		return default_direction
	elif can_look_at and manual_aim:
		last_valid_position = target_position
	
	return target_transform

func _physics_process(delta) -> void:
	if ai_debug == true:
		return
	
	if current_beam != null: # Do not put this after flux overload. We don't really want an already in-progress beam to stop changing positions on overload.
		current_beam.global_transform = WeaponNode.global_transform
		#current_beam.rotation = self.rotation
	if flux_overload == true:
		return
	if manual_aim:
		var mouse_position = to_local(get_global_mouse_position())
		var face_direction: Transform2D = face_weapon(mouse_position)
		WeaponNode.transform = WeaponNode.transform.interpolate_with(face_direction, delta * weapon.turn_rate)
	
	if available_targets.is_empty() == true:
		can_fire = false
		if current_beam != null and current_beam.is_continuous:
			stop_continuous_beam()
	
	if killcast.enabled == true and available_targets.is_empty() == false:
		var target_position: Vector2 = Vector2.ZERO
		if available_targets.has(primary_target):
			target_position = to_local(available_targets[primary_target].global_position)
		elif available_targets.has(current_target):
			target_position = to_local(available_targets[current_target].global_position)
		
		killcast.target_position = target_position
		killcast.force_raycast_update()
		var collider = killcast.get_collider()
		# Do not attempt to put these conditionals in the same line. You will regret it.
		if collider == null:
			can_fire = false
		if not (collider is Ship or collider is ShieldSlot):
			can_fire = false
		elif (collider is Ship or collider is ShieldSlot) and is_friendly == collider.is_friendly: # Do not shoot at friendly ships
			can_fire = false
		else:
			can_fire = true
		
		if can_fire == true:
			var collision_point: Vector2 = to_local(killcast.get_collision_point())
			var dist_to: float = position.distance_to(collision_point)
			if dist_to > weapon.range:
				can_fire = false
			else:
				can_fire = true
		
		if (auto_aim or auto_fire):
			var face_direction: Transform2D = face_weapon(target_position)
			WeaponNode.transform = WeaponNode.transform.interpolate_with(face_direction, delta * weapon.turn_rate)
			if can_fire == false or can_look_at == false:
				if current_beam != null and current_beam.is_continuous:
					stop_continuous_beam()
		
		if can_look_at and can_fire and timer_fire and auto_fire:
			fire(owner_rid.get_id())
			if AI_enabled == true and primary_target != RID() and primary_target == current_target:
				target_in_range.emit(true)
		if available_targets.size() >= 1 and can_fire == false and AI_enabled == true:
			acquire_new_target_AI()
		elif available_targets.size() >= 1 and can_fire == false and AI_enabled == false:
			acquire_new_target()

# this function has two purposes:
# A) updates the raycast every physics frame to track a ship's current position
# B) checks to see if a ship the player targets is within the effective range of the weapon
#func update_killcast(delta) -> void:

# Creates the context for a weapon's given situation.
func _on_EffectiveRange_entered(body) -> void:
	if body.get_rid() == owner_rid: 
		return # ignore any overlap with other weapon slots
	
	if is_friendly == body.is_friendly:
		return # ignore friendly ships if its a player (true == true) and vice versa for enemy ships (false == false)
	elif body.get_collision_layer_value(2) or body.get_collision_layer_value(4) or body.get_collision_layer_value(5): 
		return # ignore obstacle and projectile and shield layers, respectively
	
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_transform.origin, body.global_position, 7, [self, owner_rid])
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var raycast_query: Dictionary = space_state.intersect_ray(query)
	if raycast_query.is_empty():
		return # ignore if nothing is detected by the query
	if raycast_query["collider"].get_collision_layer_value(2):
		return # ignore if an obstacle is in the way
	
	var ship_id = body.get_rid()
	if not available_targets.has(ship_id):
		available_targets[ship_id] = body
	
	if not weighted_targets.has(ship_id):
		new_threats.emit(body)
	
	if AI_enabled == true:
		EffectiveRange_entered_AI(body)
	elif current_target == RID():
		current_target = ship_id

func EffectiveRange_entered_AI(body) -> void:
	var ship_id = body.get_rid()
	if available_targets.has(primary_target) and current_target != primary_target:
		killcast.target_position = to_local(available_targets[primary_target].global_position)
		current_target = primary_target
		killcast.force_raycast_update()
		if SoftlockTimer.is_stopped() == false:
			SoftlockTimer.stop()
	elif available_targets.has(current_target):
		killcast.target_position = to_local(available_targets[current_target].global_position)
		killcast.force_raycast_update()
	else:
		acquire_new_target_AI()

# Flips bools, removes references, and attempts to find other targets, all based off different ships leaving
# the effective range and the current combat situation.
func _on_EffectiveRange_exited(body) -> void:
	var ship_id: RID = body.get_rid()
	available_targets.erase(ship_id)
	
	if ship_id == primary_target:
		SoftlockTimer.start()

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
	current_target = ship_instance.get_rid()
	killcast.target_position = to_local(ship_instance.global_position)
	killcast.force_raycast_update()

# Acquire a new target if:
# A) The primary target or current target is no longer available.
# B) The weapon cannot fire on the primary target or current target.
func acquire_new_target_AI() -> void:
	if weighted_targets.is_empty():
		return
	
	var max_prob: float = weighted_targets.keys().max()
	var max_targets: Array = weighted_targets[max_prob]
	for target in max_targets:
		if target == null:
			continue
		elif not available_targets.keys().has(target):
			continue
		elif available_targets.keys().has(target):
			killcast.target_position = to_local(available_targets[target].global_position)
			current_target = target
			killcast.force_raycast_update()
			return
	
	for prob in weighted_targets:
		var enemies: Array = weighted_targets[prob]
		for target in enemies:
			if target == null:
				continue
			elif not available_targets.has(target):
				continue
			elif available_targets[target] == null:
				continue
			elif available_targets.has(target):
				killcast.target_position = to_local(available_targets[target].global_position)
				current_target = target
				killcast.force_raycast_update()
				return
	current_target = RID()

func _on_ROF_timeout() -> void:
	timer_fire = true

func _on_Softlock_timeout() -> void:
	if not available_targets.has(primary_target):
		acquire_new_target_AI()
		target_in_range.emit(false)
	else:
		target_in_range.emit(true)
		current_target = primary_target
		killcast.target_position = to_local(available_targets[primary_target].global_position)
