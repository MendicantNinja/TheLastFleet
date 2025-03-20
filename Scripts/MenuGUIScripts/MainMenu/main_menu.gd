extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$ListContainer/NewGameButton.grab_focus()
	#%NewGameButton.pressed.connect(Callable(globals, "play_gui_audio_string").bind("confirm"))
	#%NewGameButton.mouse_entered.connect(Callable(globals, "play_gui_audio_string").bind("hover"))
	#
	#%LoadGameButton.pressed.connect(Callable(globals, "play_gui_audio_string").bind("confirm"))
	#%LoadGameButton.mouse_entered.connect(Callable(globals, "play_gui_audio_string").bind("hover"))
	#
	#%SkirmishButton.pressed.connect(Callable(globals, "play_gui_audio_string").bind("confirm"))
	#%SkirmishButton.mouse_entered.connect(Callable(globals, "play_gui_audio_string").bind("hover"))
	connect_buttons_lazy()
#
func connect_buttons_lazy() -> void:
	for child in $ListContainer.get_children():
		if child is TextureButton:
			child.pressed.connect(Callable(globals, "play_gui_audio_string").bind("select"))
			child.mouse_entered.connect(Callable(globals, "play_gui_audio_string").bind("hover"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
