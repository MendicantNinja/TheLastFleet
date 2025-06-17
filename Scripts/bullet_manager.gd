extends Node2D
class_name BulletManager

var sprite: Texture2D
var SharedArea: Area2D
var bullets: Array = []
var owner_rid: RID
var shield_rid: RID
var is_friendly: bool = false

func _physics_process(delta) -> void:
	var bullet_transform: Transform2D = Transform2D()
	var bullets_queued_for_deletion: Array = []
	for i in range(0, bullets.size()):
		var bullet: Bullet = bullets[i]
		bullet.lifetime -= delta
		if bullet.lifetime < 0.0:
			#print("bullet ", debug_n_iterator, " end position: ", bullet.current_position)
			#debug_n_iterator += 1
			bullets_queued_for_deletion.append(bullet)
			continue
		bullet.current_position += bullet.direction * bullet.speed * delta
		bullet_transform.origin = bullet.current_position
		PhysicsServer2D.area_set_shape_transform(SharedArea.get_rid(), i, bullet_transform)
	
	for bullet in bullets_queued_for_deletion:
		PhysicsServer2D.free_rid(bullet.shape_rid)
		bullets.erase(bullet)
	
	queue_redraw()

func _draw() -> void:
	#var offset = sprite.get_size() / 2.0
	for bullet: Bullet in bullets:
		#print("bullet ", debug_iterator, " should render to screen at position ", bullet.current_position)
		draw_set_transform(bullet.current_position, bullet.direction.angle(), Vector2(1,1))
		draw_texture(sprite, Vector2.ZERO)

func _exit_tree():
	for bullet in bullets:
		PhysicsServer2D.free_rid(bullet.shape_rid)
	bullets.clear()

func spawn_bullet(weapon: Weapon, initial_position: Vector2, direction: Vector2, ship_id: RID) -> void:
	var bullet: Bullet = Bullet.new()
	bullet.current_position = initial_position  # Use WeaponNode.global_transform
	#print("bullet ", debug_iterator, " starting position: ", initial_position)
	#debug_iterator += 1
	# Calculate spread based on the weapon's accuracy
	var radian_accuracy = deg_to_rad(weapon.accuracy)
	var random_angle = randf_range(-radian_accuracy, radian_accuracy)
	bullet.direction = direction.rotated(random_angle) # Use WeaponNode.transform.x for the direction
	
	bullet.speed = weapon.projectile_speed
	bullet.lifetime = weapon.range / weapon.projectile_speed
	bullet.damage = weapon.damage_per_shot
	bullet.damage_type = weapon.damage_type
	bullet.owner_rid = ship_id
	
	register_to_physics_space(bullet)
	
	bullets.append(bullet)

# If a projectile requires any other collision shape, then bullet_transform will look like this:
# bullet_transform = Transform2D(bullet.direction.angle(), bullet.current_position)
func register_to_physics_space(bullet: Bullet) -> void:
	var bullet_transform: Transform2D = Transform2D(0, bullet.current_position)
	
	var circle_shape = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(circle_shape, 8)
	
	PhysicsServer2D.area_add_shape(SharedArea.get_rid(), circle_shape, bullet_transform)
	
	bullet.shape_rid = circle_shape

func _on_SharedArea_body_shape_entered(body_rid, body, body_shape_index, local_shape_index) -> void:
	if body_rid == shield_rid or body_rid == owner_rid:
		return
	
	var shape_rid: RID = PhysicsServer2D.area_get_shape(SharedArea.get_rid(), local_shape_index)
	var bullet: Bullet = null
	for n_bullet in bullets:
		if n_bullet.shape_rid == shape_rid:
			bullet = n_bullet
			break
	
	assert(bullet != null, "Found no bullet matching the local shape index in bullet manager.")
	
	if body is ShieldSlot and body.ShieldShape.disabled == true:
		return
	
	if body is ShieldSlot and body.ship_id == owner_rid.get_id():
		return
	
	if body.collision_layer == 2:
		PhysicsServer2D.free_rid(bullet.shape_rid)
		bullets.erase(bullet)
		return
	
	body.process_damage(bullet)
	PhysicsServer2D.free_rid(bullet.shape_rid)
	bullets.erase(bullet)
