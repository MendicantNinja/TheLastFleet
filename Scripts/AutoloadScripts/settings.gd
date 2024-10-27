extends Node

var player_color: Color = Color8(200, 100, 25, 255)
var enemy_color: Color = Color8(255, 50, 50)
var gui_color: Color = Color8(50, 50, 255, 255)


# For things that are partially transparent, use swizzle rather than modulating the value directly.
func swizzle(swizzled: CanvasItem) -> void:
	swizzled.self_modulate.r = gui_color.r
	swizzled.self_modulate.g = gui_color.g
	swizzled.self_modulate.b = gui_color.b

func swizzle_and_brighten_player_color(swizzled: CanvasItem) -> void:
	swizzled.self_modulate.r = player_color.r + 40
	swizzled.self_modulate.g = player_color.g + 40
	swizzled.self_modulate.b = player_color.b + 40
	
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
