extends TextureButton
class_name TacticalMapIcon

@onready var Direction: TextureRect 
@onready var Outline: TextureButton 
@onready var assigned_ship: Ship
@onready var RetreatAnimation = $AnimationPlayer
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		Outline.button_pressed = true
	else:
		Outline.button_pressed = false

func highlight_selection(value: bool) -> void:
	Outline.button_pressed = value

func setup(ship: Ship) -> void:
	assigned_ship = ship
	self.texture_normal = ship.ShipSprite.texture
	#TacticalMapShipIcon.size = Vector2(50, 50)
	Direction = $Direction
	Outline = $Outline
	if ship.is_friendly:
		Outline.self_modulate = Color8(21, 187, 0, 255)
		Direction.self_modulate = Color8(21, 187, 0, 255)
		material = load("res://Shaders/CombatGUIShaders/tactical_map_ship_icon_friendly.tres")
	else:
		Outline.self_modulate = Color8(175, 47, 34, 255)
		Direction.self_modulate = Color8(175, 47, 34, 255)
		material = load("res://Shaders/CombatGUIShaders/tactical_map_ship_icon_enemy.tres")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print(Outline.button_pressed)
	pass

func toggle_retreat_animation(value: bool) -> void:
	if value == true:
		RetreatAnimation.play(&"retreat_flash")
		print("retreating unit should flash")
	elif value == false:
		RetreatAnimation.play(&"RESET")
