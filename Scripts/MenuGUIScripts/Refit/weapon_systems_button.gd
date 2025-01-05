extends TextureButton

@onready var WeaponSystemDisplayPanel: Panel = %WeaponSystemDisplayPanel
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#$OnHoverGlowSheen.hide()
	self.pressed.connect(self.on_button_pressed)
	settings.swizzle(self, settings.gui_color)

func _unhandled_key_input(event):
	if event.keycode == KEY_ESCAPE and WeaponSystemDisplayPanel.visible == true:
		WeaponSystemDisplayPanel.visible = false
	if event.keycode == KEY_W and event.is_pressed():
		emit_signal("pressed")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_button_pressed() -> void:
	if WeaponSystemDisplayPanel.visible == true:
		WeaponSystemDisplayPanel.visible = false
	elif WeaponSystemDisplayPanel.visible == false:
		WeaponSystemDisplayPanel.visible = true
