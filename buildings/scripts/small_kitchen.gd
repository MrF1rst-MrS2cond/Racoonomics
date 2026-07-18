@tool
extends FuncBuildings
var world_grid : WorldGrid
var cooked_item : ItemType
#var cooked_amount : int
var animation_speed: float = 1.0
var is_working: bool = false 
@onready var animation_player: AnimationPlayer = $kitchen_lvl2_full/AnimationPlayer

func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid
	animation_player.play(&"Rig_Rabbit_001|Sleep",-1,animation_speed)
	if !is_ghost:
		pass
		#animation_player.play(&"Rig_Rabbit_001|Rig_Rabbit_001|Kithen_Lvl2_Work")
	



#func tick_produce(tick: int) -> void:
#	if cooked_item:
#		storage[&"cook_out"].put(cooked_item, 1)
#		cooked_item = null

func setup_building(grid_ref: WorldGrid) -> void:
	self.world_grid = grid_ref
	if storage.has(&"cook_in"):
		if storage[&"cook_in"].item_added.is_connected(_on_cook_in_item_added):
			storage[&"cook_in"].item_added.disconnect(_on_cook_in_item_added)
		storage[&"cook_in"].item_added.connect(_on_cook_in_item_added)


func on_click_harvest():
	worktime = 6
	if not is_working:
		_process_food_consumption_kitchen()

#func tick_consume(tick: int) -> void:
#	for item_id in storage[&"cook_in"].stacks:
#		cooked_item = get_recipe(Global.get_type(item_id))
#		storage[&"cook_in"].stacks.erase(item_id)

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
			#var input_type = Global.get_type(item_id)
			#amount_to_cook = input_storage.stacks[item_id]
			#var amount_to_take : int = min(amount_to_cook, items_needed)
			#cooked_item = get_recipe(Global.get_type(item_id))
			#input_storage.stacks.erase(item_id)
			#break

		if current_recipe and total_taken > 0:
			animation_player.play(&"Rig_Rabbit_001|Work",-1,animation_speed)
			await animation_player.animation_finished
			storage[&"cook_out"].put(current_recipe, total_taken)
			worktime -= 1
		else:
				break
	is_working = false
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
