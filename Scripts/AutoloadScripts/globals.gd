extends Node

func play_audio_pitched(sound: AudioStream, position: Vector2 ) -> void:
	# Universal Setup
	var audio_stream_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	audio_stream_player.autoplay = true
	audio_stream_player.pitch_scale = audio_stream_player.pitch_scale * randf_range(.80, 1.2)
	#audio_stream_player.max_distance = 1600
	# Variable Setup
	audio_stream_player.stream = sound #randomize later on if we do multiple samples
	audio_stream_player.position = position
	audio_stream_player.volume_db = settings.sound_effect_volume
	
	add_child(audio_stream_player)
	audio_stream_player.finished.connect(audio_stream_player.queue_free)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
