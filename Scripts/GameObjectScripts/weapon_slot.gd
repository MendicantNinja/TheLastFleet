extends Node2D
class_name WeaponSlot

# Nodes
@onready var weapon_mount_image: Sprite2D = $WeaponNode/WeaponMountSprite
@onready var weapon_image: Sprite2D = $WeaponNode/WeaponMountSprite/WeaponSprite
@onready var effective_range_shape: CollisionShape2D = $EffectiveRange/EffectiveRangeShape
@onready var effective_range: Area2D = $EffectiveRange
@onready var weapon_node: Node2D = $WeaponNode

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
var auto_aim: bool = false
var auto_fire: bool = false
var can_fire: bool = false
var is_friendly: bool = false
var target_engaged: bool = false

var available_targets: Dictionary = {}
var killcast: RayCast2D = null
var target_ship_position: Vector2 = Vector2.ZERO
var target_ship_id: RID
var current_target_id: RID
var arc_in_radians: float = 0.0
var default_direction: Transform2D
var owner_rid: RID

# Called to spew forth a --> SINGLE <-- projectile scene from the given Weapon in the WeaponSlot. Firing speed is tied to delta in ship.gd.
func fire(ship_id: int) -> void:
	if weapon == data.weapon_dictionary.get(data.weapon_enum.EMPTY):
		return
	#for i in weapon.burst_size: # <--- 1 by default. not important yet, but you can see how this can be used for burst functionality
		#weapon.create_projectile()
	var projectile: Area2D = weapon.create_projectile().instantiate()
	projectile.assign_stats(weapon, ship_id)
	projectile.global_transform = weapon_node.global_transform
	get_tree().root.add_child(projectile)

# Only called by ship_stats.initialize() or on implicit new in the generic ship scene. Never again.
func _init(p_weapon_mount: WeaponMount = data.weapon_mount_dictionary.get(data.weapon_mount_enum.SMALL_BALLISTIC), p_weapon: Weapon = data.weapon_dictionary.get(data.weapon_enum.EMPTY)):
	weapon_mount = p_weapon_mount
	weapon = p_weapon

func _ready():
	weapon_mount_image.texture = weapon_mount.image
	weapon_image.texture = weapon.image
	z_index = 1
	
	if position.y > 0:
		weapon_node.transform = weapon_node.transform.rotated(PI/2)
	elif position.y < 0:
		weapon_node.transform = weapon_node.transform.rotated(-PI/2)
	default_direction = weapon_node.transform
	arc_in_radians = deg_to_rad(weapon_mount.firing_arc / 2.0)

	var new_shape: Shape2D = CircleShape2D.new()
	new_shape.radius = weapon.range
	effective_range_shape.shape = new_shape
	effective_range.body_entered.connect(_on_EffectiveRange_entered)
	effective_range.body_exited.connect(_on_EffectiveRange_exited)
	set_weapon_size_and_color()

func detection_parameters(mask: int, friendly_value: bool, owner_value: RID) -> void:
	effective_range.collision_mask = mask
	is_friendly = friendly_value
	owner_rid = owner_value
	if not is_friendly:
		auto_aim = true

func set_auto_aim() -> void:
	if auto_aim == false:
		auto_aim = true
	else:
		auto_aim = false

func set_auto_fire() -> void:
	if auto_fire == false:
		auto_fire = true
	else:
		auto_fire = false

func set_target_ship(ship_id: RID) -> void:
	target_ship_id = ship_id

func set_weapon_size_and_color():
	weapon_mount_image.modulate = settings.player_color
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
	if killcast and not target_engaged and current_target_id == RID():
		killcast.target_position = to_local(body.global_position)
		current_target_id = ship_id
	elif killcast and target_ship_id == ship_id:
		killcast.target_position = to_local(body.global_position)
		target_engaged = true
	killcast.force_raycast_update()
	
	if not available_targets.has(ship_id):
		available_targets[ship_id] = body


func _on_EffectiveRange_exited(body) -> void:
	var ship_id: RID = body.get_rid()
	if available_targets.has(ship_id):
		available_targets.erase(ship_id)
	
	if ship_id == target_ship_id:
		target_engaged = false
	
	if killcast and available_targets.is_empty():
		killcast.queue_free()
		killcast = null
		current_target_id = RID()
	elif killcast:
		acquire_new_target()

# Instance a new raycast for target acquisition.
func create_killcast() -> RayCast2D:
	var new_killcast: RayCast2D = RayCast2D.new()
	new_killcast.collide_with_bodies = true
	new_killcast.collide_with_areas = false
	new_killcast.collision_mask = 7
	return new_killcast

func acquire_new_target() -> void:
	print(get_parent().name)
	print(name)
	print(available_targets.size())
	var tmp_avat: Dictionary = available_targets
	if tmp_avat.has(current_target_id):
		print(current_target_id)
		tmp_avat.erase(current_target_id)
	var ship_ids: Array = tmp_avat.keys()
	var taq_range: int = ship_ids.size() - 1
	var rand_key_number: int = randi_range(0, taq_range)
	var new_target_id = ship_ids[rand_key_number]
	var ship_instance = tmp_avat[new_target_id]
	var test_position = to_local(ship_instance.global_position)
	var test_transform = face_weapon(test_position)
	if can_fire == true:
		killcast.target_position = test_position
		killcast.force_raycast_update()

func face_weapon(target_position: Vector2) -> Transform2D:
	var target_transform: Transform2D = weapon_node.transform.looking_at(target_position)
	var scale_transform: Vector2 = weapon_node.scale
	target_transform = target_transform.scaled(scale_transform)
	var dot_product: float = default_direction.x.dot(target_transform.x)
	var angle_to_node: float = acos(dot_product)
	can_fire = true
	if angle_to_node > arc_in_radians or dot_product < 0:
		if get_parent().name == &"PlayerShip0":
			pass
		can_fire = false
		return default_direction
	return target_transform

func _physics_process(delta) -> void:
	if killcast:
		update_killcast()
	if killcast and (auto_aim or auto_fire):
		var face_direction: Transform2D = face_weapon(killcast.target_position)
		weapon_node.transform = weapon_node.transform.interpolate_with(face_direction, delta * weapon.turn_rate)
	if killcast and auto_fire and can_fire:
		fire(owner_rid.get_id())
	elif killcast and available_targets.size() > 1 and (auto_aim or auto_fire) and not can_fire:
		acquire_new_target()

func update_killcast() -> void:
	var collider = killcast.get_collider()
	if not collider is Ship: # Do not shoot at obstacles
		can_fire = false
		return
	if collider is Ship and is_friendly == collider.is_friendly: # Do not shoot at friendly ships
		can_fire = false
		return
	current_target_id = collider.get_rid()
	killcast.target_position = to_local(collider.global_position)
