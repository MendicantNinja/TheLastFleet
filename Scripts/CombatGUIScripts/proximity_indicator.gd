extends Control
@onready var IndicatorTexture: TextureRect 
@onready var Distance: RichTextLabel 

var arrow_length: float = 50.0
var arrow_width: float = 20.0
var proximity: int
# Called when the node enters the scene tree for the first time.
func setup(ship: Ship) -> void:
	IndicatorTexture = $IndicatorSprite
	Distance = $IndicatorSprite/RichTextLabel
	IndicatorTexture.texture = ship.ShipSprite.texture
	if ship.is_friendly:
		Distance.modulate = settings.player_color
	else:
		Distance.modulate = settings.enemy_color

func update_distance(distance: int) -> void:
	if distance < 5:
		self.visible = false
	else:
		self.visible = true
	proximity = snapped(distance, 10)
	Distance.text = str(proximity)
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
