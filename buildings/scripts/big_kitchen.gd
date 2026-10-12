@tool
extends KitchenBase

@export var recipes: Array[BigRecipe] = []
@export var ingredients_per_type: int = 18 # на 1 базовый крафт
@export var output_per_craft: int = 36 # выход за 1 крафт
@export var max_crafts_per_step: int = 2 # порций за раз


func _init() -> void:
	player_path = ^"kitchen_lvl2_full/AnimationPlayer"
	anim_start = &"Rig_Rabbit_001|Sleep"
	anim_idle = &"Rig_Rabbit_001|Idle"
	anim_work = &"Rig_Rabbit_001|Work"
	anim_sleep = &"Rig_Rabbit_001|Sleep"
	anim_sleep_idle = &"Rig_Rabbit_001|Sleep_Idle"


func get_big_recipe(item_a: ItemType, item_b: ItemType) -> BigRecipe:
	for recipe in recipes:
		if recipe and recipe.matches(item_a, item_b):
			return recipe
	return null


## Первая пара предметов с рецептом. {} - не нашли
func _find_pair(ids: Array[StringName]) -> Dictionary:
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var recipe := get_big_recipe(Global.get_type(ids[i]), Global.get_type(ids[j]))
			if recipe and recipe.result:
				return {"a": ids[i], "b": ids[j], "recipe": recipe}
	return {}


func _work() -> void:
	var input := storage[&"cook_in"]
	running = true
	while worktime > 0:
		var enough: Array[StringName] = [] # хватает на крафт
		for id in input.stacks:
			if input.stacks[id] >= ingredients_per_type:
				enough.append(id)
		if enough.size() < 2:
			break

		var pair := _find_pair(enough)
		if pair.is_empty():
			break
		var id_a: StringName = pair["a"]
		var id_b: StringName = pair["b"]
		var recipe: BigRecipe = pair["recipe"]

		var crafts := mini(mini(input.stacks[id_a], input.stacks[id_b]) / ingredients_per_type, max_crafts_per_step)
		if crafts <= 0:
			break

		var amount := ingredients_per_type * crafts
		take_stack(input, id_a, amount)
		take_stack(input, id_b, amount)

		show_label(worktime)
		await play_wait(anim_work)
		storage[&"cook_out"].put(recipe.result, output_per_craft * crafts)
		worktime -= 1
		set_label_count(worktime)

	running = false
	rest(worktime == 0)
