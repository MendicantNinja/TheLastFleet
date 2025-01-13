extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	%MainMenuButton.pressed.connect(self.return_to_menu)
func return_to_menu():
	get_tree().change_scene_to_file("res://Scenes/GameScenes/MainMenu.tscn")
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta):
	pass
