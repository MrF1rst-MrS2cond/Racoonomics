@tool
class_name KitchenBase
extends FuncBuildings
## База кухонь: простые рецепты (small_recipes)


func _input_key() -> StringName:
	return &"cook_in"


func _on_ready() -> void:
	play_anim(anim_start)


func get_recipe(type: ItemType) -> ItemType:
	return small_recipes[type] if small_recipes.has(type) else null


func _work() -> void:
	var input := storage[&"cook_in"]
	running = true
	while not input.stacks.is_empty() and (not manual or worktime > 0):
		var recipe: ItemType = null
		var taken := 0
		var left := portion
		for id in input.stacks.keys():
			if left <= 0:
				break
			var amount := mini(input.stacks[id], left)
			if amount > 0:
				recipe = get_recipe(Global.get_type(id)) # берётся последний
				if recipe:
					taken += amount
					left -= amount
					take_stack(input, id, amount)

		if not recipe or taken == 0:
			break
		if manual:
			show_label(worktime)
		await play_wait(anim_work)
		storage[&"cook_out"].put(recipe, taken)
		if manual:
			worktime -= 1
			set_label_count(worktime)

	running = false
	rest(manual and worktime == 0)
