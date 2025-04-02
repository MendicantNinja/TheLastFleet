extends Node2D
# Used to detect the type during body collisions to safely check ship_id.
@onready var Shields = $Shields
@onready var ShieldShape = $Shields/ShieldShape
@onready var ShieldVisuals: Polygon2D = $ShieldVisuals
var shield_material: Material = load("res://Shaders/CombatShaders/shield_material.tres")

var ship_id: int = 0
# Required parameters for drawing stuff
var shield_radius: float = 0.0
var aabb : Rect2 # Axis-Aligned Bounding Box, used to make an ellipse.
var shield_color: Color

var theta: float
var samples: int # More points = more of an accurate circle shape
var ellipse_scale: float 
var perimeter_points: PackedVector2Array

signal shield_hit(damage, type)

func _ready() -> void:
	Shields.area_entered.connect(_on_Shields_entered)
	

func toggle_shields(value: bool) -> void:
	if value == true:
		ShieldShape.disabled = false
			# Populate the points of and create the collision shape
			#await get_tree().create_timer(0.2).timeout # Raise Shields Gradually
	else:
		#ShieldShape.set_polygon(perimeter_points)
		#ShieldVisuals.set_polygon(perimeter_points)
		ShieldShape.disabled = true
	ShieldVisuals.visible = value
	pass

func shield_parameters(shield_arc: int, collision_layer: int, id: int, ship: Ship) -> void:
	var rectangle = ship.ShipSprite.get_rect()
	rectangle.size += rectangle.size/3
	aabb = rectangle
	
	shield_radius = aabb.end.y
	ellipse_scale = aabb.size.x/aabb.size.y # How many times bigger is the width than the height?

	theta = deg_to_rad(shield_arc)
	samples = 50 # More points = more of an accurate circle shape
	ship_id = id
	Shields.collision_layer = collision_layer
	
	var normalized_radius: Vector2 = aabb.size / max(aabb.size.x, aabb.size.y) # Normalize
		# Define a simple square (counterclockwise order)
	# Define a simple square (counterclockwise order)
	#var polygon = [
		#Vector2(-50, 50),  # Bottom-left
		#Vector2(50, 50),   # Bottom-right
		#Vector2(50, -50),    # Top-right
		#Vector2(-50, -50)    # Top-left
	#]
#
	## Define corresponding UVs in (0,1) range
	#var uvs = [
		#Vector2(0, 1),  # Bottom-left
		#Vector2(1, 1),  # Bottom-right
		#Vector2(1, 0),  # Top-right
		#Vector2(0, 0)   # Top-left
	#]
#
	## Apply to Polygon2D
	#ShieldVisuals.set_polygon(polygon)
	#ShieldVisuals.set_uv(uvs)
	#ShieldVisuals.material = shield_material.duplicate() 
	
	
	#for i in range(samples):
		#if i == 0:
			#perimeter_points.append(Vector2(0, 0))
			#continue
		#var angle: float =  -theta / 2 + (theta * i / samples)
		#perimeter_points.append(shield_radius * Vector2(cos(angle), sin(angle)*ellipse_scale))
		#ShieldShape.set_polygon(perimeter_points)
		#ShieldVisuals.set_polygon(perimeter_points)
		##perimeter_points.clear()
	#var uv_points: PackedVector2Array
	#for i in range(perimeter_points.size()):
		#var uv_x = (perimeter_points[i].x / aabb.size.x + 1.0) * 0.5  # Convert -1..1 to 0..1
		#var uv_y = (perimeter_points[i].y / aabb.size.y + 1.0) * 0.5
		##if i == 0:
			##uv_y = 0.00
		#var uv: Vector2 = Vector2(uv_x, uv_y)
		#uv_points.append(uv)
	#ShieldVisuals.set_uv(uv_points)
	ShieldVisuals.material = shield_material.duplicate() 
	#ShieldVisuals.material.set_shader_parameter("ellipse_radius", normalized_radius)

func _on_Shields_entered(projectile: Node2D) -> void: # Do not change the type to projectile.
	print("on_shields entered")
	if not projectile is Projectile:
		return
	
	if projectile.ship_id == ship_id:
		return
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
