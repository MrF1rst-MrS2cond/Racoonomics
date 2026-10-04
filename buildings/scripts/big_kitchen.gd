@tool
extends FuncBuildings

@export var recipes: Array[BigRecipe] = []
@export var ingredients_per_type: int = 18  # По сколько предметов каждого типа нужно на 1 базовый крафт
@export var output_per_craft: int = 36       # Сколько готовой продукции выходит за 1 базовый крафт
@export var max_crafts_per_step: int = 2     # Сколько порций за один раз может обработать кухня (2 = 36x2)

var label_scene: PackedScene = preload("res://UI/scenes/clikfarm.tscn")
var current_label: Node3D = null

var world_grid: WorldGrid
var animation_speed: float = 1.0
var is_working: bool = false 

@onready var animation_player: AnimationPlayer = $kitchen_lvl2_full/AnimationPlayer


func _process(_delta: float) -> void:
	if is_instance_valid(current_label) and animation_player.is_playing():
		var anim_length := animation_player.current_animation_length
		if anim_length > 0.0:
			var current_pos := animation_player.current_animation_position
			var progress_ratio := current_pos / anim_length
			
			if current_label.has_method("set_progress"):
				current_label.set_progress(progress_ratio)


func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid
	animation_player.play(&"Rig_Rabbit_001|Sleep", -1, animation_speed)


func setup_building(grid_ref: WorldGrid) -> void:
	self.world_grid = grid_ref
	if storage.has(&"cook_in"):
		if storage[&"cook_in"].item_added.is_connected(_on_cook_in_item_added):
			storage[&"cook_in"].item_added.disconnect(_on_cook_in_item_added)
		storage[&"cook_in"].item_added.connect(_on_cook_in_item_added)


func on_click_harvest():
	worktime = 12

	if not is_working:
		_process_food_consumption_kitchen()


func _ensure_click_label() -> void:
	if is_ghost or Engine.is_editor_hint():
		return

	if is_instance_valid(current_label):
		return

	current_label = label_scene.instantiate() as Node3D
	current_label.building_owner = self

	get_tree().current_scene.add_child(current_label)

	if current_label.has_method("update_label_position"):
		current_label.update_label_position()


func _update_label_count() -> void:
	if is_instance_valid(current_label) and current_label.has_method("set_count"):
		current_label.set_count(worktime)


func _on_cook_in_item_added(_item_id: StringName) -> void:
	if is_working:
		return
	_process_food_consumption_kitchen()


func _process_food_consumption_kitchen() -> void:
	var input_storage := storage[&"cook_in"]
	
	while worktime > 0:
		# 1. Отбираем предметы, которых хватает хотя бы на 1 крафт (>= ingredients_per_type)
		var valid_item_ids: Array[StringName] = []
		for item_id in input_storage.stacks.keys():
			if input_storage.stacks[item_id] >= ingredients_per_type:
				valid_item_ids.append(item_id)

		if valid_item_ids.size() < 2:
			break
			
		# 2. Ищем подходящий рецепт
		var found_id_a: StringName = &""
		var found_id_b: StringName = &""
		var current_recipe: BigRecipe = null

		for i in range(valid_item_ids.size()):
			for j in range(i + 1, valid_item_ids.size()):
				var id_a := valid_item_ids[i]
				var id_b := valid_item_ids[j]
				var type_a: ItemType = Global.get_type(id_a)
				var type_b: ItemType = Global.get_type(id_b)
				
				var recipe := get_big_recipe(type_a, type_b)
				if recipe and recipe.result:
					found_id_a = id_a
					found_id_b = id_b
					current_recipe = recipe
					break
			if current_recipe:
				break

		if not current_recipe:
			break

		# 3. Высчитываем, сколько порций крафта мы можем обработать за этот шаг
		var available_a: int = input_storage.stacks[found_id_a]
		var available_b: int = input_storage.stacks[found_id_b]
		
		var possible_crafts_a := available_a / ingredients_per_type
		var possible_crafts_b := available_b / ingredients_per_type
		
		# Берем минимум из доступных ингредиентов и ограничения max_crafts_per_step
		var multiplier := mini(mini(possible_crafts_a, possible_crafts_b), max_crafts_per_step)
		
		if multiplier <= 0:
			break

		is_working = true

		# 4. Списываем ингредиенты кратно числу порций (multiplier)
		var take_amount := ingredients_per_type * multiplier
		
		input_storage.stacks[found_id_a] -= take_amount
		if input_storage.stacks[found_id_a] <= 0:
			input_storage.stacks.erase(found_id_a)

		input_storage.stacks[found_id_b] -= take_amount
		if input_storage.stacks[found_id_b] <= 0:
			input_storage.stacks.erase(found_id_b)

		_ensure_click_label()
		_update_label_count()

		animation_player.play(&"Rig_Rabbit_001|Work", -1, animation_speed)
		await animation_player.animation_finished

		# Выгружаем результат кратно числу порций
		var total_output := output_per_craft * multiplier
		storage[&"cook_out"].put(current_recipe.result, total_output)
		
		worktime -= 1
		_update_label_count()

	is_working = false

	if is_instance_valid(current_label):
		current_label.queue_free()
		current_label = null

	if worktime == 0:
		if animation_player.current_animation != &"Rig_Rabbit_001|Sleep_Idle":
			animation_player.play(&"Rig_Rabbit_001|Sleep", -1, animation_speed)
			await animation_player.animation_finished
			animation_player.play(&"Rig_Rabbit_001|Sleep_Idle", -1, animation_speed)
	else:
		animation_player.play(&"Rig_Rabbit_001|Idle", -1, animation_speed)


func get_big_recipe(item_a: ItemType, item_b: ItemType) -> BigRecipe:
	for recipe in recipes:
		if recipe and recipe.matches(item_a, item_b):
			return recipe
	return null


func _exit_tree() -> void:
	if is_instance_valid(current_label):
		current_label.queue_free()
