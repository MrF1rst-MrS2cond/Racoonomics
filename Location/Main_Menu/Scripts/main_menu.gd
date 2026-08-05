extends Node2D

@onready var tutorial_popup: TextureRect = $TutorialPopup
@onready var blocker_panel: Panel = $Panel

@onready var btn_true: Button = $TutorialPopup/TextureRect/True
@onready var btn_false: Button = $TutorialPopup/TextureRect/False

var popup_tween: Tween

func _ready() -> void:
	close_tutorial_popup_instantly()
	
	if btn_true:
		btn_true.pressed.connect(_on_tutorial_yes_pressed)
	if btn_false:
		btn_false.pressed.connect(_on_tutorial_no_pressed)

func _process(_delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if tutorial_popup.visible:
			animate_close_popup()
			get_viewport().set_input_as_handled()

# --- ОСНОВНЫЕ КНОПКИ МЕНЮ ---

func _on_play_pressed() -> void:
	animate_open_popup()

func _on_authors_pressed() -> void:
	get_tree().change_scene_to_file("res://Location/Main_Menu/Scenes/authors.tscn")

func _on_additional_pressed() -> void:
	get_tree().change_scene_to_file("res://Location/Main_Menu/Scenes/Additional.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

# --- АНИМАЦИИ И УПРАВЛЕНИЕ ЗАГЛУШКОЙ ---

func close_tutorial_popup_instantly() -> void:
	tutorial_popup.hide()
	blocker_panel.hide()
	blocker_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE # Отключаем перехват кликов

func animate_open_popup() -> void:
	if popup_tween and popup_tween.is_running():
		popup_tween.kill()
		
	blocker_panel.mouse_filter = Control.MOUSE_FILTER_STOP # Включаем блокировку кликов!
	
	# Выставляем Pivot по центру и сбрасываем масштаб для ОБОИХ элементов
	tutorial_popup.pivot_offset = tutorial_popup.size / 2.0
	tutorial_popup.scale = Vector2.ZERO
	
	var card = $TutorialPopup/TextureRect
	if card:
		card.pivot_offset = card.size / 2.0
		card.scale = Vector2.ZERO
		
	blocker_panel.show()
	tutorial_popup.show()
	blocker_panel.modulate.a = 0.0

	popup_tween = create_tween().set_parallel(true)
	popup_tween.tween_property(blocker_panel, "modulate:a", 1.0, 0.2)
	
	# Анимируем сразу внешнюю рамку и внутренний текст/кнопки
	popup_tween.tween_property(tutorial_popup, "scale", Vector2.ONE, 0.35)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	if card:
		popup_tween.tween_property(card, "scale", Vector2.ONE, 0.35)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)

func animate_close_popup() -> void:
	if popup_tween and popup_tween.is_running():
		popup_tween.kill()
		
	var card = $TutorialPopup/TextureRect
	
	popup_tween = create_tween().set_parallel(true)
	popup_tween.tween_property(blocker_panel, "modulate:a", 0.0, 0.2)
	
	# Плавно сжимаем обратно внешнюю рамку
	popup_tween.tween_property(tutorial_popup, "scale", Vector2.ZERO, 0.2)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
		
	if card:
		popup_tween.tween_property(card, "scale", Vector2.ZERO, 0.2)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_IN)
		
	await popup_tween.finished
	close_tutorial_popup_instantly()

# --- ВЫБОР ИГРОКА И ПЕРЕХОД НА ЛОКАЦИЮ ---

func _on_tutorial_yes_pressed() -> void:
	Global.is_tutorial_enabled = true
	start_game()

func _on_tutorial_no_pressed() -> void:
	Global.is_tutorial_enabled = false
	start_game()

func start_game() -> void:
	get_tree().change_scene_to_file("res://Location/Main_Menu/Scenes/location.tscn")
