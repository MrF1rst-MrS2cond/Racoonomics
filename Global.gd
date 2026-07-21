extends Node

@export var type_lookup : Dictionary[StringName, ItemType]
var loyalty : int
var current_loyalty_total: int = 0

signal update_bar(int)
signal money_value_changed(new_value:int)
signal update_bar_percent(percent: float)

func _ready() -> void:
	var types_dir := DirAccess.open("res://resources/item_types")
	if !types_dir:
		push_error("item type lookup population failed, could not open directory")
		return

	types_dir.list_dir_begin()
	var file_name := types_dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var type := ResourceLoader.load("res://resources/item_types/" + file_name) as ItemType
			if type:
				type_lookup[type.id] = type
			else:
				push_warning("failed to load item type from file: " + file_name)
		file_name = types_dir.get_next()

func get_type(id: StringName) -> ItemType:
	return type_lookup.get(id, null)


func add_loyalty(loyalty_amount: int) -> void:
	current_loyalty_total += loyalty_amount
	recalculate_loyalty_bar()
	
	# Потоковый ресурс: затухание через 9 секунд
	await get_tree().create_timer(9.0).timeout
	current_loyalty_total = max(0, current_loyalty_total - loyalty_amount)
	recalculate_loyalty_bar()


func recalculate_loyalty_bar() -> void:
	var main_scene = get_tree().current_scene
	var world_grid = main_scene.find_child("WorldGrid", true, false) as WorldGrid
	
	if not world_grid:
		update_bar_percent.emit(0.0)
		return

	var current_hub_level: int = 1
	var active_countries: Array = []
	
	# 1. Находим текущий уровень Хаба и активные районы
	for building in world_grid.buildings_cache:
		if is_instance_valid(building):
			if building is Hub:
				current_hub_level = building.Hublevel
			elif building is CountryZone:
				# Проверяем, открыт ли район для текущего уровня Хаба
				if building.required_hub_level <= current_hub_level:
					active_countries.append(building)

	if active_countries.is_empty():
		update_bar_percent.emit(0.0)
		return

	# 2. Считаем суммарное максимальное значение преданности для всех ОТКРЫТЫХ районов
	# Предполагаем, что у каждого CountryZone есть свойство population (количество жителей)
	var total_max_capacity: float = 0.0
	for country in active_countries:
		# Если у CountryZone заведено поле населения, используем его. 
		# Если поле называется иначе (например, population), замени ниже:
		var pop = country.population if "population" in country else 10 
		total_max_capacity += float(pop) # 1 житель = 10 единиц преданности до заполнености района

	var final_percent: float = 0.0
	if total_max_capacity > 0:
		# Распределяем текущую преданность игрока относительно максимума открытых районов
		final_percent = (float(current_loyalty_total) / total_max_capacity) * 100.0

	# Ограничиваем диапазон от 0 до 100%
	update_bar_percent.emit(clamp(final_percent, 0.0, 100.0))
