extends Node3D

@onready var world_grid: WorldGrid = $WorldGrid

func _ready() -> void:
	world_grid._occupy_rect(Rect2i(3, -1, 1, 2), self)
	
	# Проверяем, включено ли обучение
	if Global.is_tutorial_enabled:
		start_tutorial_level_1()
	else:
		print("Игрок пропустил обучение — сразу обычная игра")

## Старт туториала 1-го уровня по сценарию
func start_tutorial_level_1() -> void:
	print("Запуск туториала с Енотом!")
	
