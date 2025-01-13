extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	update_buttons_gui()

func update_buttons_gui() -> void:
	for child in self.get_children():
		settings.swizzle(child, settings.gui_color)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
