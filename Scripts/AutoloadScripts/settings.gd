extends Node

var player_color: Color = Color8(200, 100, 25, 255)
var enemy_color: Color = Color8(255, 50, 50, 255)
var gui_color: Color = Color8(50, 50, 255, 255)


# For things that are partially transparent, use swizzle rather than assigning the value directly lest opacity/alpha be set to 255.
func swizzle(swizzled: CanvasItem, color: Color = gui_color) -> void:
	swizzled.self_modulate.r = color.r
	swizzled.self_modulate.g = color.g
	swizzled.self_modulate.b = color.b

func swizzle_and_darken(swizzled: CanvasItem, color: Color = gui_color) -> void:
	swizzled.self_modulate.r = color.r - 40
	swizzled.self_modulate.g = color.g - 40
	swizzled.self_modulate.b = color.b - 40

func swizzle_and_brighten_player_color(swizzled: CanvasItem, color: Color = player_color) -> void:
	swizzled.self_modulate.r = color.r + 40
	swizzled.self_modulate.g = color.g + 40
	swizzled.self_modulate.b = color.b + 40
	
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
