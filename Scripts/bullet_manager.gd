extends Node2D
class_name BulletManager

var sprite: Image
var shared_area: Area2D
var bullets: Array = []

func spawn_bullet(weapon: Weapon, initial_position: Vector2, direction: Vector2, ship_id: int, is_friendly: bool) -> void:
	var bullet: Bullet = Bullet.new()
	bullet.current_position = initial_position  # Use WeaponNode.global_transform
	
	# Calculate spread based on the weapon's accuracy
	var radian_accuracy = deg_to_rad(weapon.accuracy)
	var random_angle = randf_range(-radian_accuracy, radian_accuracy)
	bullet.direction = direction.rotated(random_angle) # Use WeaponNode.transform.x for the direction
	
	bullet.speed = weapon.projectile_speed
	bullet.lifetime = weapon.range / weapon.projectile_speed
	bullet.damage = weapon.damage_per_shot
	bullet.damage_type = weapon.damage_type
	bullet.owner_id = ship_id
	
	register_to_physics_space(bullet, weapon)
	
	bullets.append(bullet)

# If a projectile requires any other collision shape, then used_transform will look like this:
# used_transform = Transform2D(bullet.direction.angle(), bullet.current_position)
func register_to_physics_space(bullet: Bullet, weapon: Weapon) -> void:
	var used_transform: Transform2D = Transform2D(0, bullet.current_position)
	
	var circle_shape = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(circle_shape, 8)
	
	PhysicsServer2D.area_add_shape(shared_area.get_rid(), circle_shape, used_transform)
	
	bullet.shape_id = circle_shape
