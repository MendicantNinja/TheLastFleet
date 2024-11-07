extends TextureButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$OnHoverGlowSheen.hide()
	self.pressed.connect(self.new_game_pressed)
	self.pressed.connect(self.on_pressed)
	self.focus_entered.connect(self.on_focus_entered)
	self.mouse_entered.connect(self.on_mouse_entered)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func new_game_pressed() -> void:
	pass
	#$NewGamePopup.position.y = self.global_position.y #+ (self.size.y * 69/250)
	#$NewGamePopup.position.x = self.global_position.x + (self.size.x)/1.2
	#$NewGamePopup.size = Vector2i(Vector2(get_viewport().size)*Vector2(.156,.185))
	#$NewGamePopup.show() 
	#$NewGamePopup/VBoxContainer/HBoxContainer/NoButton.grab_focus()
	
func on_focus_entered() -> void:
	pass
	#var gui_noise_player: AudioStreamPlayer = AudioStreamPlayer.new()
	#self.add_child(gui_noise_player)
	#
	#var gui_noise = load("res://Noises of GUI/ButtonSelect.ogg")
	#gui_noise_player.stream = gui_noise
	#gui_noise_player.play()
	#
	#await gui_noise_player.finished
	#gui_noise_player.queue_free()

func on_mouse_entered() -> void:
	print("On mouse entered called")
	#$OnHoverGlowSheen.show()
	pass
	# Display OnHoverSheen
	
	#var gui_noise_player: AudioStreamPlayer  = AudioStreamPlayer.new()
	#self.add_child(gui_noise_player)
	#
	#var gui_noise = load("res://Noises of GUI/SpellSkillHover.ogg")
	#gui_noise_player.stream = gui_noise
	#gui_noise_player.play()
	#
	#await gui_noise_player.finished
	#gui_noise_player.queue_free()

func on_pressed() -> void:
	pass
	#var gui_noise_player: AudioStreamPlayer  = AudioStreamPlayer.new()
	#self.add_child(gui_noise_player)
	#
	#var gui_noise = load("res://Noises of GUI/ButtonConfirm.ogg")
	#gui_noise_player.stream = gui_noise
	#gui_noise_player.play()
	#
	#await gui_noise_player.finished
	#gui_noise_player.queue_free()
