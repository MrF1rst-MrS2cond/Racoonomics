extends Control

@onready var level_spin_box: SpinBox = $Panel/SpinBox
@onready var btn_apply_level: Button = $Panel/BtnApplyLevel
@onready var btn_max_money: Button = $Panel/BtnMaxMoney

func _ready() -> void:
	hide() # При старте игры консоль закрыта
	
	# Подключаем нажатия кнопок к функциям
	if btn_apply_level:
		btn_apply_level.pressed.connect(_on_apply_level_pressed)
	if btn_max_money:
		btn_max_money.pressed.connect(_on_max_money_pressed)

func _unhandled_input(event: InputEvent) -> void:
	# Открываем/закрываем консоль на кнопку "C" (Eng/Рус)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			visible = !visible
			get_viewport().set_input_as_handled()

# Чит на изменение уровня Хаба
func _on_apply_level_pressed() -> void:
	var target_level: int = int(level_spin_box.value)
	var main_scene = get_tree().current_scene
	
	if not main_scene:
		return

	# 1. Меняем Hublevel у здания Хаба
	var world_grid = main_scene.find_child("WorldGrid", true, false)
	if world_grid and "buildings_cache" in world_grid:
		for building in world_grid.buildings_cache:
			if is_instance_valid(building) and (building is Hub or "Hublevel" in building):
				building.Hublevel = target_level
				print("Чит: Уровень объекта Hub успешно изменен на ", target_level)
				break

	# 2. Ищем узел с методом refresh_unlocked_buildings абсолютно везде внутри сцены
	var main_ui_nodes = main_scene.find_children("*", "", true, false)
	var ui_found: bool = false
	
	for node in main_ui_nodes:
		if node.has_method("refresh_unlocked_buildings"):
			node.refresh_unlocked_buildings()
			ui_found = true
			if node.has_method("_get_current_hub_level"):
				print("Чит: Main_UI найден! Теперь он видит уровень Хаба как: ", node._get_current_hub_level())
			break

	if not ui_found:
		# На всякий случай проверяем сам корень сцены
		if main_scene.has_method("refresh_unlocked_buildings"):
			main_scene.refresh_unlocked_buildings()
		else:
			printerr("Чит: Скрипт с методом refresh_unlocked_buildings не найден в сцене!")

	# 3. Обновляем страны и преданность
	Global.on_hub_level_changed()

# Чит на восполнение бюджета до текущего максимума
func _on_max_money_pressed() -> void:
	var main_scene = get_tree().current_scene
	if not main_scene:
		return
		
	# Ищем узел MoneyManager на текущей сцене
	var money_manager = main_scene.find_child("MoneyManager", true, false)
	
	if not money_manager:
		for child in main_scene.get_children():
			if "max_money" in child and "money" in child:
				money_manager = child
				break

	if money_manager:
		money_manager.money = money_manager.max_money
		print("Чит: Бюджет полностью восстановлен до ", money_manager.max_money)
	else:
		printerr("Чит: Узел MoneyManager не найден на сцене!")
