extends Node3D

@onready var audio_player: AudioStreamPlayer3D = $SplashAudio

func _ready() -> void:
	if audio_player and audio_player.stream:
		audio_player.play()
		# Ждем завершения проигрывания звука
		var stream_duration = audio_player.stream.get_length()
		await get_tree().create_timer(stream_duration).timeout
	else:
		await get_tree().create_timer(1.0).timeout
		
	queue_free()
