extends Node

@export var type_lookup : Dictionary[StringName, ItemType]
var loyalty : int
var current_loyalty_total: int = 0
var is_loyality_max = false

# Новые переменные для отсрочки в 1 секунду
var can_upgrade_hub: bool = false
var grace_timer: SceneTreeTimer = null

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


func add_loyalty(loyalty_amount: int, duration: float) -> void:
	current_loyalty_total += loyalty_amount
	recalculate_loyalty_bar()
	
	await get_tree().create_timer(duration).timeout
	current_loyalty_total = max(0, current_loyalty_total - loyalty_amount)
	recalculate_loyalty_bar()

func on_hub_level_changed() -> void:
	recalculate_loyalty_bar()

func recalculate_loyalty_bar() -> void:
	var main_scene = get_tree().current_scene
	if not main_scene:
		return
		
	var world_grid = main_scene.find_child("WorldGrid", true, false) as WorldGrid
	
	if not world_grid:
		update_bar_percent.emit(0.0)
		return

	var current_hub_level: int = 1
	var active_countries: Array = []

	# 1. Ищем уровень Хаба в buildings_cache
	for building in world_grid.buildings_cache:
		if is_instance_valid(building) and building is Hub:
			current_hub_level = building.Hublevel
			break

	# 2. Ищем страны среди дочерних нод WorldGrid
	for child in world_grid.get_children():
		if is_instance_valid(child) and child is CountryZone:
			if child.required_hub_level <= current_hub_level:
				active_countries.append(child)

	if active_countries.is_empty():
		update_bar_percent.emit(0.0)
		return

	var total_max_capacity: float = 0.0
	for country in active_countries:
		var current_pop = country.get_population_for_level(current_hub_level)
		total_max_capacity += float(current_pop)

	var final_percent: float = 0.0
	if total_max_capacity > 0:
		final_percent = (float(current_loyalty_total) / total_max_capacity) * 100.0

	var clamped_percent = clamp(final_percent, 0.0, 100.0)
	update_bar_percent.emit(clamped_percent)

	# Логика 1-секундного окна при падении
	if clamped_percent >= 100.0:
		is_loyality_max = true
		can_upgrade_hub = true
		grace_timer = null
	else:
		is_loyality_max = false
		if can_upgrade_hub and grace_timer == null:
			grace_timer = get_tree().create_timer(1.0)
			grace_timer.timeout.connect(_on_grace_timer_timeout)

func _on_grace_timer_timeout() -> void:
	if not is_loyality_max:
		can_upgrade_hub = false
	grace_timer = null
