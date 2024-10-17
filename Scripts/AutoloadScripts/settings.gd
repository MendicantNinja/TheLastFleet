extends Node

var player_color: Color = Color(50, 50, 255, 255)
var gui_color: Color = Color8(203, 125, 35, 255)
# Called when the node enters the scene tree for the first time.
func swizzle(swizzled: CanvasItem) -> void:
	swizzled.self_modulate.r = gui_color.r
	swizzled.self_modulate.g = gui_color.g
	swizzled.self_modulate.b = gui_color.b

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
