extends Control
class_name HintPanel

@onready var video_player: VideoStreamPlayer = $TextureRect/VideoStreamPlayer
@onready var text_label: RichTextLabel = $TextureRect/TextLabel
@onready var close_button: Button = $TextureRect/BtClose

@export var on_screen_x: float = 20.0
@export var slide_duration: float = 0.4

var off_screen_x: float = -500.0

func _ready() -> void:
	off_screen_x = -size.x - 50.0
	if close_button:
		close_button.pressed.connect(hide_hint)

## Функция заготовки: принимает текст и видео (видео не обязательно!)
func setup(text: String, video_path: String = "") -> void:
	if text_label:
		text_label.text = text
		
	if video_player and video_path != "":
		var stream_res = load(video_path) as VideoStream
		if stream_res:
			video_player.stream = stream_res
			
	show_hint()

func show_hint() -> void:
	position.x = off_screen_x
	show()
	if video_player and video_player.stream:
		video_player.play()
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", on_screen_x, slide_duration)

func hide_hint() -> void:
	if video_player:
		video_player.stop()
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", off_screen_x, slide_duration)
	
	await tween.finished
	queue_free() # Удаляем подсказку из памяти после задвигания
