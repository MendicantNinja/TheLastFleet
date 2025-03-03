extends Node2D

const maxrange = 5000

var based_width = 10
var widthy = based_width
var shoot = false
@onready var collision = $Line2D/DamageArea/CollisionShape2D

func _ready():
 pass # Replace with function body.


func _process(delta):
 
 $Line2D.width = widthy
 
 var mouse_position = get_local_mouse_position()
 var max_cast_to = mouse_position.normalized() * maxrange
 $RayCast2D.target_position = max_cast_to

 if $RayCast2D.is_colliding():
  $Reference.global_position = $RayCast2D.get_collision_point()
  $Line2D.set_point_position(1,$Line2D.to_local($Reference.global_position))
 else:
  $Reference.global_position = $RayCast2D.target_position
  $Line2D.points[1] = $Reference.global_position

 if shoot == true:
  collision.shape.b = $Line2D.points[1]
  collision.disabled = false
  $Line2D.visible = true
 else:
  collision.shape.b = Vector2.ZERO
  collision.disabled = true
  $Line2D.visible = false
  
 if Input.is_action_pressed("click"):
  shoot = true
 else:
  shoot = false
