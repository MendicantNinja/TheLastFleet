extends Node2D

var decals = []
var max_decals = 10

func _on_ship_hit(hit_position: Vector2, hit_ship: Node2D):
	spawn_decal(hit_ship)

func spawn_decal(hit_ship: Node2D):
	if decals.size() >= max_decals:
		var oldest_decal = decals.pop_front()
		oldest_decal.queue_free()
	
	var decal = preload("res://bulletdecal.tscn").instantiate()
	hit_ship.add_child(decal)
	
	# Get the ship's sprite dimensions to place decals within its bounds
	var ship_sprite = hit_ship.get_node("ShipSprite")
	var sprite_size = ship_sprite.texture.get_size() * ship_sprite.scale
	
	# Generate random position within the ship's bounds
	var random_x = randf_range(-sprite_size.x/2, sprite_size.x/2)
	var random_y = randf_range(-sprite_size.y/2, sprite_size.y/2)
	decal.position = Vector2(random_x, random_y)
	
	decal.rotation = randf_range(0, 2 * PI)  # Random rotation
	decal.scale = Vector2.ONE * randf_range(0.8, 1.2)  # Random scale
	decals.append(decal)
