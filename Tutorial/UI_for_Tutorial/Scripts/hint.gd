extends Control

@onready var video_player: VideoStreamPlayer = $TextureRect/VideoStreamPlayer
@onready var close_button: Button = $TextureRect/BtClose

@export var on_screen_x: float = 20.0
@export var slide_duration: float = 0.4

var off_screen_x: float = -500.0

func _ready() -> void:
	off_screen_x = -size.x - 50.0
	
	if close_button:
		close_button.pressed.connect(hide_hint)
	
	show_hint()

func show_hint() -> void:
	position.x = off_screen_x
	show()
	
	video_player.stop()
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", on_screen_x, slide_duration)
	
	await tween.finished
	
	video_player.play()

func hide_hint() -> void:
	video_player.stop()
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", off_screen_x, slide_duration)
	
	await tween.finished
	hide()
