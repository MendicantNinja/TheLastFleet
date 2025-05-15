extends TextureButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#$OnHoverGlowSheen.hide()
	settings.swizzle(self, settings.gui_color)
	self.pressed.connect(self.on_button_pressed)
	self.focus_entered.connect(self.on_focus_entered)
	#self.mouse_entered.connect(self.on_mouse_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Not actually new game, I just copy paste code.
func on_button_pressed() -> void:
	var scene = load("res://Scenes/GameScenes/CombatArena.tscn") as PackedScene
	var instance = scene.instantiate()
	get_tree().root.add_child(instance)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = instance
	instance.setup(Fleet.new(), 3)
	

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
