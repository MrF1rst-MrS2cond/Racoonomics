@tool
extends FuncBuildings
class_name SmallKitchenLvl2

var world_grid : WorldGrid
var animation_speed: float = 1.0
var is_working: bool = false
@onready var animation_player: AnimationPlayer = $kitchen_lvl3_full/AnimationPlayer

func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid
	if animation_player:
		animation_player.play(&"Armature|Lvl3_idle", -1, animation_speed)


func setup_building(grid_ref: WorldGrid) -> void:
	self.world_grid = grid_ref
	if storage.has(&"cook_in"):
		if storage[&"cook_in"].item_added.is_connected(_on_cook_in_item_added):
			storage[&"cook_in"].item_added.disconnect(_on_cook_in_item_added)
		storage[&"cook_in"].item_added.connect(_on_cook_in_item_added)


func _on_cook_in_item_added(_item_id: StringName) -> void:
	if is_working:
		return
	_process_food_consumption_kitchen()

func on_click_harvest() -> void:
	pass

func _process_food_consumption_kitchen() -> void:
	var input_storage := storage[&"cook_in"]
	while input_storage.stacks.size() > 0:
		is_working = true
		var items_needed := 36
		var current_recipe: ItemType = null
		var total_taken: int = 0
		
		for item_id in input_storage.stacks.keys():
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
			if animation_player:
				animation_player.play(&"Armature|Lvl3_work", -1, animation_speed)
				await animation_player.animation_finished
			
			storage[&"cook_out"].put(current_recipe, total_taken)
		else:
			# Если рецепт не найден или ингредиенты закончились — выходим из цикла
			break

	is_working = false
	if animation_player:
		animation_player.play(&"Armature|Lvl3_idle", -1, animation_speed)


func get_recipe(produce_food: ItemType) -> ItemType:
	if small_recipes.has(produce_food):
		return small_recipes[produce_food] as ItemType
	return null
