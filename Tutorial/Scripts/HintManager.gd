extends Node

var hint_scene: PackedScene = preload("res://Tutorial/UI_for_Tutorial/ScenesForUI/Hint.tscn")
var current_hint: HintPanel = null

func _ready() -> void:
	pass

### Универсальная функция для вызова любой подсказки из любого места игры
func show_tutorial_hint(text: String, video_path: String = "") -> void:
	if is_instance_valid(current_hint):
		current_hint.hide_hint()
		
	var main_ui = get_tree().current_scene.find_child("Main_UI", true, false)
	if main_ui:
		current_hint = hint_scene.instantiate() as HintPanel
		main_ui.add_child(current_hint)
		current_hint.setup(text, video_path)

### Функция для закрытия текущей подсказки
func close_current_hint() -> void:
	if is_instance_valid(current_hint):
		current_hint.hide_hint()
		current_hint = null
