extends TextureButton
class_name ShipIcon

var index: int
var ship: ShipStats
@onready var ship_sprite: TextureButton = $ShipSprite
@onready var ship_label: Label = $ShipSprite/Label

func on_added_to_container() -> void:
	self.toggled.connect(get_parent().on_icon_toggled.bind(self)) #bind this signal during fleet deployment setup
	self.ship_sprite.self_modulate = settings.player_color

func _ready() -> void:
	self.pressed.connect(Callable(globals, "play_gui_audio_string").bind("select"))
	self.mouse_entered.connect(Callable(globals, "play_gui_audio_string").bind("hover"))
