extends Area2D
class_name Projectile

@onready var Sprite: Sprite2D = $Sprite2D

# Stats
@onready var track_distance: Vector2 = Vector2.ZERO
var damage: int = 0 
var speed: float = 0
var range: int = 0
var damage_type: int = 0

# For Beams Only
var is_beam = false
var is_continuous = false
var beam_duration: float
var beam_raycast: RayCast2D = null
var beam_line: Line2D = null
var beam_end: Vector2 
var beam_damage_timer: Timer = null
var weapon_slot_rotation: float
# Can't circularly reference the weapon slot directly. So update the beam!

# For Missiles and Tracking Projectiles Only
var is_missile: bool = false
var is_seeking: bool = false

# For other stuff:
var owner_rid: RID
var ship_id: int

signal projectile_freed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	z_index = 1
	input_pickable = false
	collision_layer = 8
	collision_mask = 31
	self.body_entered.connect(_on_projectile_collision)
#
func _physics_process(delta) -> void:
	if is_beam == false:
		var next_position: Vector2 = transform.x * delta * speed
		position += next_position
		track_distance += next_position
		if track_distance.length() >= range:
			queue_free()
	elif is_beam == true:
		beam_end = beam_raycast.target_position  # Default to max length
		#if owner_rid.is_valid() == false:
			#queue_free()
		if beam_raycast.is_colliding():
			var target = beam_raycast.get_collider()
			if target is Projectile:
				if target.ship_id == ship_id:
					return
			beam_end = to_local(beam_raycast.get_collision_point())  # Stop at collision
			beam_line.points[1] = beam_end
			
			if beam_damage_timer.is_stopped() == true:
				#print("Emitting signal for beam weapon")
				_on_projectile_collision(target)
				beam_damage_timer.start()


# Should be called when the projectile is created in weapon_slot.gd.
func assign_stats(weapon: Weapon, rid: RID, shield_rid: RID, friendly_value: bool) -> void: 
	damage = weapon.damage_per_shot
	speed = weapon.projectile_speed
	range = weapon.range
	damage_type = weapon.damage_type
	owner_rid = rid
	ship_id = owner_rid.get_id()
	var radian_accuracy = deg_to_rad(weapon.accuracy)
	var lower_limit = -radian_accuracy
	var upper_limit = radian_accuracy
	var spread: Transform2D = transform
	var rand_rotation: float = randi_range(-1, 1) * randf_range(lower_limit, upper_limit)
	spread = spread.rotated_local(rand_rotation)
	transform = spread
	
	is_beam = weapon.is_beam
	is_continuous = weapon.is_continuous
	if is_beam == true:
		#beam_collision_line = $CollisionShape2D # Beam Collision shape isn't used.
		#beam_collision_line.shape.b.x = range # Beam collision shape distance
		beam_duration = weapon.beam_duration
		beam_raycast = $RayCast2D
		beam_raycast.add_exception_rid(owner_rid)
		beam_raycast.add_exception_rid(shield_rid)
		beam_raycast.target_position.x = range # Beam Raycast
		beam_line = $Line2D
		beam_damage_timer = $beam_damage_timer
		beam_damage_timer.wait_time = 0.05 # Emit damage call every 0.05s
		if is_continuous == false:
			var tween: Tween = create_tween()
			tween.tween_property(beam_line, "modulate", Color(1, 1, 1, 0), beam_duration)
			tween.finished.connect(func(): 
				queue_free()  # Free projectile after fading out
				emit_signal("projectile_freed")  # Emit signal after freeing
)
		beam_raycast.collision_mask = 31
		beam_line.set_point_position(1, Vector2(range, 0)) # Where is the beam drawn.

# What happens when the projectile hits? We have damage and the collided_object_instance for the enemy to calculate.
func _on_projectile_collision(body) -> void:
	if body == null:
		return
	var body_id: RID = body.get_rid()
	if body_id == owner_rid:
		return
	if damage == 0:
		push_error("No weapon detected for projectile scene. res://Scenes/CompositeGameObjects/Projectiles/RailgunProjectile.tscn")
		return
	
	var body_layer: int = body.collision_layer
	if body_layer == 2: # obstacle layer
		queue_free()  # Free projectile after fading out
		emit_signal("projectile_freed")  # Emit signal after freeing
		return
	
	#if body is Projectile: # Collide with enemy projectiles (point defense). 
		#if body.is_friendly == false:
			#body.process_damage()
	# Collision acceptance and damage processing is handled by shield_slot.gd
	# This is due to ShieldSlot being an area. Rather than a body.
	if body is ShieldSlot:
		if body.ship_id == ship_id:
			return
		body.process_damage(self)
		if is_beam == false:
			queue_free()
			return
	
	# Contact with a ship (and later on in dev,  projectiles with hull integrity)
	if body is Ship:
		body.process_damage(self)
		if is_beam == false:
			queue_free()
			return
		#if is_continuous == false:
	
	# Contact with a shield

	
