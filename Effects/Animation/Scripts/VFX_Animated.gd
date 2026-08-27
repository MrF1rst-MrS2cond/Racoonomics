extends AnimatedSprite3D

@onready var audio_player: AudioStreamPlayer3D = $SplashAudio

func _ready() -> void:
	play("play_vfx")
	if audio_player and audio_player.stream:
		audio_player.play()
	
	# Ждем окончания анимации
	await animation_finished
	queue_free()
