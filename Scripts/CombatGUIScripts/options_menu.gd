extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	%MainMenuButton.pressed.connect(self.return_to_menu)
	for child in self.get_children():
		if child is TextureButton:
			child.pressed.connect(Callable(globals, "play_gui_audio_string").bind("select"))
			child.mouse_entered.connect(Callable(globals, "play_gui_audio_string").bind("hover"))
	
	
func return_to_menu():
	get_tree().change_scene_to_file("res://Scenes/GameScenes/MainMenu.tscn")
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta):
	pass
