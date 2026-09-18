@tool
extends FuncBuildings

var label_scene: PackedScene = preload("res://UI/scenes/clikfarm.tscn")
var current_label: Node3D = null

var world_grid : WorldGrid
var cooked_item : ItemType
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
	while worktime > 0 and input_storage.stacks.size() > 0:
		is_working = true
		var items_needed := 18
		var current_recipe: ItemType = null
		var total_taken: int = 0
		for item_id in storage[&"cook_in"].stacks.keys():
			if items_needed <= 0:
				break
			var available_count: int = input_storage.stacks[item_id]
			var amount_to_take: int = int(min(available_count, items_needed))
			if amount_to_take > 0:
				var input_type: ItemType = Global.get_type(item_id)
				current_recipe = get_recipe(input_type)
				if current_recipe:
					total_taken += amount_to_take
					items_needed -= amount_to_take
					input_storage.stacks[item_id] -= amount_to_take
					if input_storage.stacks[item_id] <= 0:
						input_storage.stacks.erase(item_id)

		if current_recipe and total_taken > 0:
			# Спавним часы ТОЛЬКО когда есть рецепт и ресурсы
			_ensure_click_label()
			_update_label_count()

			animation_player.play(&"Rig_Rabbit_001|Work", -1, animation_speed)
			await animation_player.animation_finished
			storage[&"cook_out"].put(current_recipe, total_taken)
			worktime -= 1
			_update_label_count()
		else:
			break

	is_working = false

	# Удаляем плашку, если работа закончилась или нет ингредиентов
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


func get_recipe(produce_food: ItemType) -> ItemType:
	if small_recipes.has(produce_food):
		return small_recipes[produce_food] as ItemType
	return null


func _exit_tree() -> void:
	if is_instance_valid(current_label):
		current_label.queue_free()
