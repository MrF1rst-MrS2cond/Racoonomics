@tool
extends Building
var world_grid : WorldGrid
var cooked_item : ItemType
#var cooked_amount : int


@onready var animation_player: AnimationPlayer = $Rig_Rabbit_001/AnimationPlayer

func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid

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
		storage[&"cook_in"].item_added.connect(_on_cook_in_item_added)

#func tick_consume(tick: int) -> void:
#	for item_id in storage[&"cook_in"].stacks:
#		cooked_item = get_recipe(Global.get_type(item_id))
#		storage[&"cook_in"].stacks.erase(item_id)

func _on_cook_in_item_added(_item_id: StringName) -> void:
	var amount_to_cook := 0
	var input_storage := storage[&"cook_in"]
	for item_id in storage[&"cook_in"].stacks:
		var input_type = Global.get_type(item_id)
		amount_to_cook = input_storage.stacks[item_id]
		cooked_item = get_recipe(Global.get_type(item_id))
		input_storage.stacks.erase(item_id)
		break

	if cooked_item and amount_to_cook > 0:
		animation_player.play(&"Rig_Rabbit_001|Rig_Rabbit_001|Kithen_Lvl2_Work")
		await animation_player.animation_finished
		storage[&"cook_out"].put(cooked_item, amount_to_cook)
		cooked_item = null

func get_recipe(produce_food: ItemType) -> ItemType:
		return small_recipes.get(produce_food, ItemType)
