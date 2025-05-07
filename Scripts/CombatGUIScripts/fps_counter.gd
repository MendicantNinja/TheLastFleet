extends RichTextLabel

var fps: float = 0.0
var fps_string: String = ""

func _ready() -> void:
	self.bbcode_enabled = true
	self.size.x = 256
	self.size.y = 128

func _process(_delta: float) -> void:
	fps = Engine.get_frames_per_second()
	fps_string = "  FPS: "

	if fps >= 60.0:
		fps_string += "[color=green]"

	elif fps >= 30.0:
		fps_string += "[color=yellow]"

	else:
		fps_string += "[color=red]"

	fps_string += str(fps) + "[/color]"
	self.text = fps_string
