extends Node2D

@onready var Shields: Area2D = $Shields
@onready var ShieldShape: CollisionPolygon2D = $Shields/ShieldShape
@onready var ShieldVisuals: Polygon2D = $ShieldVisuals
var shield_material: Material = load("res://Shaders/CombatShaders/shield_material.tres")

var ship_id: int = 0
# Required parameters for drawing stuff
var shield_radius: float = 0.0
var aabb : Rect2 # Axis-Aligned Bounding Box, used to make an ellipse.
var shield_color: Color

var theta: float
var samples: int # More points = more of an accurate circle shape
var ellipse_scale: Vector2 
var perimeter_points: PackedVector2Array

signal shield_hit(damage, type)

func _ready() -> void:
	Shields.area_entered.connect(_on_Shields_entered)

func toggle_shields(value: bool) -> void:
	#var pass_through = 0
	if value == true:
		print("toggle shields called true")
		ShieldShape.disabled = false
		
		ShieldVisuals.visible = true
		# Precompute points
		perimeter_points.append(Vector2(0, 0))
		for i in range(samples):
			var direction = 1 if i % 2 == 1 else -1  # Alternate R/L
			var step = ceil(i / 2.0)  # 1,1,2,2,3,3...
			var angle: float 

			angle = -theta / 2 + (theta * i / samples)
			perimeter_points.append(shield_radius * Vector2(cos(angle), sin(angle)))
			#ShieldShape.set_polygon(perimeter_points)
			#ShieldVisuals.set_polygon(perimeter_points)
		#perimeter_points.append(Vector2(0, 0))
		
		var polygon_array: Array[Vector2]
		var center: int = samples/2
		for i in range(center): # Samples of 30 = 15 loops
			if ShieldShape.disabled == true:
				return
			var left_boundary = center - i + 1 # center - 1 + 1 = 15
			var right_boundary = center + i + 1 # center + 1 + 1 = 17
			polygon_array.clear()
			polygon_array.append(Vector2(0, 0))
			for point in range(left_boundary, right_boundary+1): # Stops before n.
				polygon_array.append(perimeter_points[point])
			
			ShieldShape.set_polygon(polygon_array)
			ShieldVisuals.set_polygon(polygon_array)
			await get_tree().create_timer(0.2).timeout # Raise Shields Gradually
		#polygon_array.append(Vector2(0, 0))
	elif value == false:
		ShieldShape.disabled = true
		perimeter_points.clear()
		ShieldShape.set_polygon(perimeter_points)
		ShieldVisuals.set_polygon(perimeter_points)
		ShieldVisuals.visible = value
	pass
	# Setup the shields parameters initially.
func shield_parameters(shield_arc: int, collision_layer: int, id: int, ship: Ship) -> void:
	ShieldVisuals.material = shield_material.duplicate(true) 
	var rectangle = ship.ShipSprite.get_rect()
	rectangle.size.x = max(rectangle.size.x, rectangle.size.y)
	rectangle.size.y = rectangle.size.x
	rectangle.size += rectangle.size * .5 + Vector2(20, 20)
	aabb = rectangle
	shield_radius = aabb.size.x/2
	ShieldVisuals.texture.size = aabb.size
	theta = deg_to_rad(shield_arc)
	samples = 30 # More points = more of an accurate circle shape
	ship_id = id
	Shields.collision_layer = collision_layer

	ShieldVisuals.material.set_shader_parameter("circle_radius", shield_radius)

func _on_Shields_entered(projectile: Node2D) -> void: # Do not change the type to projectile.
	if not projectile is Projectile:
		return
	if projectile.ship_id == ship_id:
		return

	print("on shields entered")

	if projectile.is_beam == true:
		#print("projectile beam process damage was called")
		# Armor should be done differently with beams. Probably. Playtesting needed.
		if projectile.is_continuous == false:
			var beam_projectile_divisor: float = projectile.beam_duration * 20.0
			var inverse_divisor: float = 1.0 / beam_projectile_divisor
			var beam_projectile_damage: int = int(projectile.damage * inverse_divisor)
			shield_hit.emit(beam_projectile_damage, projectile.damage_type)
			#print(beam_projectile_damage)
		else:
			#var beam_projectile_divisor: int = 1 / .05
			var beam_projectile_damage: int = int(projectile.damage * .05 )
			shield_hit.emit(beam_projectile_damage, projectile.damage_type)
			#print(beam_projectile_damage)
	else:
		projectile.call_deferred("queue_free")
		shield_hit.emit(projectile.damage, projectile.damage_type)
	
	
	#var shield_transform: Transform2D = global_transform
	#var look_at_projectile: Transform2D = shield_transform.looking_at(projectile.global_position)
	#var dot_product: float = shield_transform.x.dot(look_at_projectile.x)
	#var angle_to_projectile: float = acos(dot_product)
	#
	#if angle_to_projectile > shield_arc:
		#return
	#elif angle_to_projectile < shield_arc:
		#projectile.call_deferred("queue_free")
		#shield_hit.emit(projectile.damage, projectile.damage_type)
