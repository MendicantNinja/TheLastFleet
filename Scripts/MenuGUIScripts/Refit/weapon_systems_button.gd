extends TextureButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#$OnHoverGlowSheen.hide()
	self.pressed.connect(self.on_button_pressed)
	self.focus_entered.connect(self.on_focus_entered)
	self.mouse_entered.connect(self.on_mouse_entered)
	settings.swizzle(self, settings.gui_color)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Not actually new game, I just copy paste code.
func on_button_pressed() -> void:
	if %WeaponSystemDisplay.visible == true:
		%WeaponSystemDisplay.visible == false
	elif %WeaponSystemDisplay.visible == false:
		%WeaponSystemDisplay.visible == true

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
