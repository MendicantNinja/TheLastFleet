extends Node

# If dev mode is true, railgun weapons are added to the ship.gd automatically and assigned a slot. Rather than grabbing and assigning weapons from ship stats.
@onready var dev_mode = false

# Visuals
var screen_size: Vector2 = DisplayServer.screen_get_size()

var player_color: Color = Color8(25, 125, 255, 255)
var enemy_color: Color = Color8(255, 50, 50, 255)
var gui_color: Color = Color8(50, 50, 255, 255)

var ballistic_color: Color = Color (1.5, 1.5, 0, 1.0 )
var energy_color: Color = Color (.25, .25, 1.5, 1.0 )
var missile_color: Color = Color (.75, 1.5, 0, 1.0 )
var universal_color: Color = Color (.9, .9, .9, 1.0 )

var master_volume: float = 1.00
var sound_effect_volume: float = 1.00
var music_volume: float = 1.00

# For things that are partially transparent, use swizzle rather than assigning the gui/player color directly. If you don't opacity/alpha will be set to 255 always.
func swizzle(swizzled: CanvasItem, color: Color = gui_color) -> void:
	swizzled.self_modulate.r = color.r
	swizzled.self_modulate.g = color.g
	swizzled.self_modulate.b = color.b

func swizzle_and_darken(swizzled: CanvasItem, color: Color = gui_color) -> void:
	swizzled.self_modulate.r = color.r - 40
	swizzled.self_modulate.g = color.g - 40
	swizzled.self_modulate.b = color.b - 40

func swizzle_and_brighten(swizzled: CanvasItem, color: Color = gui_color) -> void:
	swizzled.self_modulate.r = color.r + 40
	swizzled.self_modulate.g = color.g + 40
	swizzled.self_modulate.b = color.b + 40
	
func _ready():
	print("Developer Mode = ", dev_mode)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
