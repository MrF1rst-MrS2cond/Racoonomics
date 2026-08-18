@tool
extends FuncBuildings

@export var recipes: Array[BigRecipe] = []

var world_grid: WorldGrid
var animation_speed: float = 1.0
var is_working: bool = false 

@onready var animation_player: AnimationPlayer = $kitchen_lvl2_full/AnimationPlayer

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

func _on_cook_in_item_added(_item_id: StringName) -> void:
	if is_working:
		return
	_process_food_consumption_kitchen()

func _process_food_consumption_kitchen() -> void:
	var input_storage := storage[&"cook_in"]
	
	while worktime > 0:
		var available_item_ids = input_storage.stacks.keys()

		if available_item_ids.size() < 2:
			break
			
		var id_a: StringName = available_item_ids[0]
		var id_b: StringName = available_item_ids[1]
		
		var type_a: ItemType = Global.get_type(id_a)
		var type_b: ItemType = Global.get_type(id_b)
		
		var current_recipe: BigRecipe = get_big_recipe(type_a, type_b)
		if not current_recipe or not current_recipe.result:
			break
			
		is_working = true
		
		input_storage.stacks[id_a] -= 18
		if input_storage.stacks[id_a] <= 0:
			input_storage.stacks.erase(id_a)
			
		input_storage.stacks[id_b] -= 18
		if input_storage.stacks[id_b] <= 0:
			input_storage.stacks.erase(id_b)

		animation_player.play(&"Rig_Rabbit_001|Work", -1, animation_speed)
		await animation_player.animation_finished
		
		storage[&"cook_out"].put(current_recipe.result, 36)
		worktime -= 1

	is_working = false
	
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
