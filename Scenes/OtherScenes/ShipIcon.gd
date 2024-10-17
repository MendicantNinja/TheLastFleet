extends TextureButton
class_name ShipIcon



var index: int
var ship: ShipStats
@onready var ship_sprite: TextureButton = $ShipSprite
@onready var ship_label: Label = $ShipSprite/Label
# Called when the node enters the scene tree for the first time.
func on_added_to_container() -> void:
	self.pressed.connect(get_parent().on_icon_toggled.bind(true, self))

func _ready():
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
