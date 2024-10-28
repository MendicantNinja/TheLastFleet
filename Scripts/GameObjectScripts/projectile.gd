extends Area2D
class_name Projectile

# Stats
@onready var track_distance: Vector2 = Vector2.ZERO
var projectile_damage: int = 0 
var projectile_speed: float = 0
var projectile_range: int = 0
var ship_id: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_pickable = false
	collision_layer = 8
	collision_mask = 15
	self.body_entered.connect(_on_Projectile_collision)

func _physics_process(delta) -> void:
	var next_position: Vector2 = transform.x * delta * projectile_speed
	position += next_position
	track_distance += next_position
	if track_distance.length() >= projectile_range:
		queue_free()

# Should be called when the projectile is created in weapon.gd.
func assign_stats(weapon: Weapon, id: int) -> void: 
	projectile_damage = weapon.damage_per_shot
	projectile_speed = weapon.projectile_speed
	projectile_range = weapon.range
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
	if projectile_damage == 0:
		push_error("No weapon detected for projectile scene. res://Scenes/CompositeGameObjects/Projectiles/RailgunProjectile.tscn")
		return
	
	var body_layer: int = body.collision_layer
	if body_layer == 2: # obstacle layer
		return 
	
	if "hull_integrity" in body:
		body.hull_integrity -= projectile_damage
	
	queue_free()
