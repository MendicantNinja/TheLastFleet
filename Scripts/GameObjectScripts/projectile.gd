extends Area2D
class_name Projectile

# Stats
@onready var track_distance: Vector2 = Vector2.ZERO
var damage: int = 0 
var speed: float = 0
var range: int = 0
var damage_type: int = 0
var ship_id: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_pickable = false
	collision_layer = 8
	collision_mask = 15
	self.body_entered.connect(_on_Projectile_collision)

func _physics_process(delta) -> void:
	var next_position: Vector2 = transform.x * delta * speed
	position += next_position
	track_distance += next_position
	if track_distance.length() >= range:
		queue_free()

# Should be called when the projectile is created in weapon.gd.
func assign_stats(weapon: Weapon, id: int) -> void: 
	damage = weapon.damage_per_shot
	speed = weapon.projectile_speed
	range = weapon.range
	damage_type = weapon.damage_type
	ship_id = id
	var radian_accuracy = deg_to_rad(weapon.accuracy)
	var lower_limit = -radian_accuracy
	var upper_limit = radian_accuracy
	var spread: Transform2D = transform
	var rand_rotation: float = randi_range(-1, 1) * randf_range(lower_limit, upper_limit)
	spread = spread.rotated_local(rand_rotation)
	transform = spread

# What happens when the projectile hits? We have damage and the collided_object_instance for the enemy to calculate.
func _on_Projectile_collision(body) -> void:
	var body_id: int = body.get_rid().get_id()
	if body_id == ship_id:
		return
	if damage == 0:
		push_error("No weapon detected for projectile scene. res://Scenes/CompositeGameObjects/Projectiles/RailgunProjectile.tscn")
		return
	
	var body_layer: int = body.collision_layer
	if body_layer == 2: # obstacle layer
		return 
	
	if "hull_integrity" in body:
		body.process_damage(self)
		queue_free()
	
	pass
