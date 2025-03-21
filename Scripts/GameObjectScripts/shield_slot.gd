extends Node2D

@onready var Shields = $Shields
@onready var ShieldShape = $Shields/ShieldShape
var ship_id: int = 0

# Required parameters for drawing the arc
var shield_type: int = -1
var shield_radius: float = 0.0

# Angles determined by shield type
var start_angle: float = 0.0
var end_angle: float = 0.0

# Default parameters for the arc representing the shield 
var line_width: float = 2.0
var inner_count: float = 64.0
var shield_color: Color = Color.BLUE

signal shield_hit(damage, type)

func _ready() -> void:
	Shields.area_entered.connect(_on_Shields_entered)
	ShieldShape.set_deferred("disabled", false)

func _draw() -> void:
	if shield_type == -1:
		return
	
	draw_arc(position, shield_radius, start_angle, end_angle, inner_count, shield_color, line_width, true)

func shield_parameters(type: int, radius: float, collision_layer: int, id: int) -> void:
	ship_id = id
	shield_type = type
	if type == -1:
		queue_redraw()
		ShieldShape.set_deferred("disabled", true)
		return
	elif type >= 0:
		ShieldShape.set_deferred("disabled", false)
	
	Shields.collision_layer = collision_layer
	match shield_type:
		1: # front shield
			start_angle = -PI/4
			end_angle = PI/4
			shield_radius = radius * 2.0
		2: # omni shield
			pass
	
	var new_shield_shape: CircleShape2D = CircleShape2D.new()
	new_shield_shape.radius = shield_radius
	ShieldShape.shape = new_shield_shape
	
	queue_redraw()

func _on_Shields_entered(projectile: Projectile) -> void:
	print("on_shields_entered ", projectile.is_continuous)
	if not projectile is Projectile:
		return
	
	if projectile.ship_id == ship_id:
		return
	
	var shield_transform: Transform2D = global_transform
	var look_at_projectile: Transform2D = shield_transform.looking_at(projectile.global_position)
	var dot_product: float = shield_transform.x.dot(look_at_projectile.x)
	var angle_to_projectile: float = acos(dot_product)
	var shield_arc: float = (end_angle - start_angle) / 2
	
	if angle_to_projectile > shield_arc:
		return
	elif angle_to_projectile < shield_arc:
		projectile.call_deferred("queue_free")
		shield_hit.emit(projectile.damage, projectile.damage_type)
