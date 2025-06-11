extends TextureButton


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	self.pressed.connect(self.on_button_pressed)
	settings.swizzle($DiscordIcon, settings.gui_color)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func on_button_pressed() -> void:
	var invite_url: String = "https://discord.gg/r5knXd325F"
	OS.shell_open(invite_url)
