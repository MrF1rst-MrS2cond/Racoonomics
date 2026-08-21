extends Node

## Максимальный лимит монет для каждого уровня Hub (Уровень: Лимит)
@export var max_money_by_level: Dictionary[int, int] = {
	1: 10,
	2: 20,
	3: 45,
	4: 80,
	5: 110,
	6: 170,
	7: 210
}

@export var default_max_money: int = 20

## Текущий максимальный лимит
var max_money: int = 20:
	set(value):
		max_money = value
		if is_node_ready():
			update_vizual()

## Текущий баланс монет
@export var money: int = 0:
	set(value):
		money = clamp(value, 0, max_money)
		if is_node_ready():
			update_vizual()

@onready var money_label: Label = $Money_count/MoneyLabel


func _ready() -> void:
	# Подключаемся к сигналу изменения уровня хаба, если он есть в Global
	if Global.has_signal("hub_level_changed"):
		Global.hub_level_changed.connect(on_hub_level_changed)
	
	# Устанавливаем начальный лимит для 1 уровня
	max_money = get_max_money_for_level(1)
	update_vizual()


## Возвращает макс. монеты для конкретного уровня хаба
func get_max_money_for_level(level: int) -> int:
	return max_money_by_level.get(level, default_max_money)


## Вызывается при повышении уровня Хаба
func on_hub_level_changed(new_hub_level: int) -> void:
	var new_max: int = get_max_money_for_level(new_hub_level)
	
	if new_max > max_money:
		var difference: int = new_max - max_money  # На сколько увеличился лимит
		max_money = new_max                         # Обновляем макс. лимит
		money += difference                         # Добавляем разницу к текущим монетам


## Проверка и списание стоимости покупки
func check_cost(cost: int) -> bool:
	if cost <= money:
		money -= cost
		update_vizual()
		return true
	return false


func update_vizual() -> void:
	if is_instance_valid(money_label):
		money_label.text = "%d/%d" % [money, max_money]
	Global.money_value_changed.emit(money, max_money)
