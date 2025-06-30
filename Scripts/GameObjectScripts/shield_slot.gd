extends RigidBody2D
class_name ShieldSlot

@onready var ShieldShape: CollisionPolygon2D = $ShieldShape
@onready var ShieldVisuals: Polygon2D = $ShieldVisuals
@onready var ShieldShape2: CollisionShape2D = $ShieldShape2
var shield_material: Material = load("res://Shaders/CombatShaders/shield_material.tres")

var ship_id: int = 0
# Required parameters for drawing stuff
var shield_radius: float = 0.0
var shield_raise_time: float = 1.0
var aabb : Rect2 # Axis-Aligned Bounding Box, used to make an ellipse.
var shield_color: Color
var is_friendly: bool

var theta: float
var samples: int # More points = more of an accurate circle shape
var ellipse_scale: Vector2 
var perimeter_points: PackedVector2Array

signal shield_hit(damage, type)

func _ready() -> void:
	pass

# Used for processing hit shaders with a timer. Process is good for vfx since it's called every frame.
const MAX_HITS := 32
var hits: Array[Dictionary] = [] # each hit = {pos, radius, timer}

func _process(delta) -> void:
	self.global_transform = owner.global_transform
	if hits.size() == 0:
		set_process(false)
		return

	for i in range(hits.size() - 1, -1, -1): # Iterate backwards so we can remove stuff.
		hits[i]["timer"] -= delta * 2.0
		if hits[i]["timer"] <= 0.0:
			hits.remove_at(i)

	# Prepare arrays for shader
	var hit_positions: Array = []
	var hit_radii: Array = []
	var hit_timers: Array = []

	for i in range(min(hits.size(), MAX_HITS)):
		hit_positions.append(hits[i]["pos"])
		hit_radii.append(hits[i]["radius"])
		hit_timers.append(clamp(hits[i]["timer"], 0.0, 1.0))

	# Send to shader
	ShieldVisuals.material.set_shader_parameter("hit_count", hit_positions.size())
	ShieldVisuals.material.set_shader_parameter("hit_positions", hit_positions)
	ShieldVisuals.material.set_shader_parameter("hit_radii", hit_radii)
	ShieldVisuals.material.set_shader_parameter("hit_timers", hit_timers)

func register_hit(uv_pos: Vector2, radius: float):
	if hits.size() >= MAX_HITS:
		hits.pop_front()
	hits.append({
		"pos": uv_pos,
		"radius": radius,
		"timer": .9
	})
	set_process(true)

func process_damage(projectile) -> void:
	if not projectile is Projectile or not projectile is Bullet:
		return
	if projectile is Projectile and projectile.ship_id == ship_id:
		return
	var local_pos: Vector2 # Where has the hit occured, in local coordinates?
	var hit_radius: float # How large should the hit effect be? It's based on damage.
	if projectile is Projectile and projectile.is_beam == true:
		#var test_position = projectile.to_global(projectile.beam_end) 
		local_pos = to_local(projectile.to_global(projectile.beam_end))
		
		#print("projectile beam process damage was called")
		# Armor should be done differently with beams. Probably. Playtesting needed.
		if projectile.is_continuous == false:
			var beam_projectile_divisor: float = projectile.beam_duration * 20.0
			var inverse_divisor: float = 1.0 / beam_projectile_divisor
			var beam_projectile_damage: int = int(projectile.damage * inverse_divisor)
			shield_hit.emit(beam_projectile_damage, projectile.damage_type)
			hit_radius = projectile.damage/500.0 * .01
			#var debug =  beam_projectile_damage/500.0 * .3
			#print("continuous beam damage is", debug)
		else:
			#var beam_projectile_divisor: int = 1 / .05
			var beam_projectile_damage: int = int(projectile.damage * .05 )
			shield_hit.emit(beam_projectile_damage, projectile.damage_type)
			hit_radius = projectile.damage/500.0 * .1
			#var debug =  beam_projectile_damage/500.0 * .3
			#print("non-continuous beam damage is", debug)
	else:
		local_pos = to_local(projectile.global_position)
		hit_radius = projectile.damage/500.0 * .2 # 500 damage = full 8 pixels
		shield_hit.emit(projectile.damage, projectile.damage_type)
		#var debug =  projectile.damage/500.0 * .5
		#print("projectile damage is", debug)
	register_hit(local_pos/aabb.size, hit_radius)


func toggle_shields(value: bool) -> void:
	#var pass_through = 0
	if value == true:
		#print("toggle shields called true")
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
		var step_duration = shield_raise_time / center
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
			await get_tree().create_timer(step_duration).timeout # Raise Shields Gradually
		#polygon_array.append(Vector2(0, 0))
	elif value == false:
		ShieldShape.set_deferred("disabled", true)
		perimeter_points.clear()
		ShieldShape.set_polygon(perimeter_points)
		ShieldVisuals.set_polygon(perimeter_points)
		ShieldVisuals.visible = value
	
	#if value == true:
		#ShieldShape.disabled = true
		#var new_shape: CircleShape2D = CircleShape2D.new()
		#new_shape.radius = shield_radius
		#ShieldShape2.shape = new_shape
		#ShieldShape2.disabled = false
	#elif value == false:
		#ShieldShape2.set_deferred("disabled", true)
	# Setup the shields parameters initially.
func shield_parameters(shield_arc: int, p_collision_layer: int, id: int, ship: Ship) -> void:
	add_collision_exception_with(ship)
	#if ship.is_friendly:
		#collision_layer = 5
	#else:
		#collision_layer = 20
	owner = ship
	ShieldVisuals.material = shield_material.duplicate(true) 
	shield_raise_time = ship.ship_stats.shield_raise_time
	var rectangle = ship.ShipSprite.get_rect()
	rectangle.size.x = max(rectangle.size.x, rectangle.size.y)
	rectangle.size.y = rectangle.size.x
	rectangle.size += rectangle.size * .5 + Vector2(20, 20)
	aabb = rectangle
	shield_radius = aabb.size.x/2
	ShieldVisuals.texture.size = aabb.size
	theta = deg_to_rad(shield_arc)
	is_friendly = ship.is_friendly
	# Samples = More points = more of an accurate circle shape, worse performance.
	# Via this formula: 15 samples for a 60 degree shield.
	# 60 samples for a 240 degree shield 
	samples = shield_arc/4 
	ship_id = id

	ShieldVisuals.material.set_shader_parameter("circle_radius", shield_radius)
	position = Vector2.ZERO
	# For omni shields, when that gets polished in.
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
