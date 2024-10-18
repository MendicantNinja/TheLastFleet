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
var is_friendly: bool = false
var target_engaged: bool = false

var owner_rid: RID
var targets_acquired: Dictionary = {}
var killcast: RayCast2D = null
var target_ship_id: int = 0
var any_ship_id: int = 0
var focus_aim: Vector2 = Vector2.ZERO

# Called to spew forth a --> SINGLE <-- projectile scene from the given Weapon in the WeaponSlot. Firing speed is tied to delta in ship.gd.
func fire(ship_id: int) -> void:
	if weapon != data.weapon_dictionary.get(data.weapon_enum.EMPTY):
		#for i in weapon.burst_size: # <--- 1 by default. not important yet, but you can see how this can be used for burst functionality
			#weapon.create_projectile()
		var projectile: Area2D = weapon.create_projectile().instantiate()
		projectile.assign_stats(weapon, ship_id)
		projectile.global_position = global_position + Vector2(0, 0) # Should come out of the edge/front of the weapon.
		projectile.global_rotation = rotation
		# Add random spread based on accuracy. Etc. 
		get_tree().root.add_child(projectile)

# Only called by ship_stats.initialize() or on implicit new in the generic ship scene. Never again.
func _init(p_weapon_mount: WeaponMount = data.weapon_mount_dictionary.get(data.weapon_mount_enum.SMALL_BALLISTIC), p_weapon: Weapon = data.weapon_dictionary.get(data.weapon_enum.EMPTY)):
	weapon_mount = p_weapon_mount
	weapon = p_weapon

func _ready():
	weapon_mount_image.texture = weapon_mount.image
	weapon_image.texture = weapon.image
	
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
	
	var collider_id: int = raycast_query["rid"].get_id()
	if not targets_acquired.has(collider_id):
		targets_acquired[collider_id] = "lol"
	
	if not killcast:
		killcast = create_killcast()
		add_child(killcast)
	
	focus_aim = to_local(body.global_position)
	killcast.target_position = focus_aim

func _on_EffectiveRange_exited(body) -> void:
	var ship_id: int = body.get_rid().get_id()
	if targets_acquired.has(ship_id):
		targets_acquired.erase(ship_id)
	
	if ship_id == any_ship_id:
		any_ship_id = 0
	elif ship_id == target_ship_id:
		target_engaged = false
	
	if killcast and targets_acquired.is_empty():
		killcast.queue_free()
		killcast = null
		focus_aim = Vector2.ZERO
	elif killcast:
		# do something related to acquiring another target (if possible)
		pass

# Called down from ship.gd for whenever the player targets a specific ship.
func update_target_parameters(ship_id: int, ship_position: Vector2) -> void:
	if target_ship_id == ship_id:
		return
	
	focus_aim = ship_position
	target_ship_id = ship_id
	
	if not killcast:
		killcast = create_killcast()
		add_child(killcast)

func create_killcast() -> RayCast2D:
	var new_killcast: RayCast2D = RayCast2D.new()
	new_killcast.collide_with_bodies = true
	new_killcast.collide_with_areas = false
	new_killcast.collision_mask = 7
	return new_killcast

func face_weapon(target_position: Vector2) -> Transform2D:
	var new_transform = weapon_node.transform.looking_at(focus_aim)
	var scale_transform = weapon_node.scale
	new_transform = new_transform.scaled(weapon_node.scale)
	return new_transform

func _physics_process(delta) -> void:
	if killcast and auto_aim:
		weapon_node.transform = face_weapon(killcast.target_position)
		update_killcast()

func update_killcast() -> void:
	var collider = killcast.get_collider()
	if not collider:
		return
	focus_aim = to_local(collider.global_position)
	killcast.target_position = focus_aim
