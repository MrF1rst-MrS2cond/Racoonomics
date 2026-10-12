@tool
class_name StoreBase
extends FuncBuildings
## База лавок: еда превращается в Преданность

@export var any_filter: ItemFilter

var anim_reject: StringName


func _input_key() -> StringName:
	return &"food_input"


func _on_ready() -> void:
	if not is_ghost:
		play_anim(anim_start)


func _on_setup() -> void:
	var zone := world_grid._get_country_zone_at_cell(origin_cell)
	if zone and zone.zone_filter != null:
		any_filter = zone.zone_filter


func _accepts(type: ItemType) -> bool:
	return not any_filter or not type or any_filter.accepts(type)


func _work() -> void:
	var input := storage[&"food_input"]
	running = true
	while not input.stacks.is_empty() and (not manual or worktime > 0):
		var first_id: StringName = input.stacks.keys()[0]
		var first_type := Global.get_type(first_id)

		if not _accepts(first_type): # зона не принимает
			take_stack(input, first_id, 1)
			await play_wait(anim_reject)
			continue

		var duration := first_type.satiety * 18.0 if first_type else 1.0
		var satiety := 0
		var left := portion
		for id in input.stacks.keys():
			if left <= 0:
				break
			if not _accepts(Global.get_type(id)):
				continue
			var amount := mini(input.stacks[id], left)
			satiety += amount
			left -= amount
			take_stack(input, id, amount)

		if satiety > 0:
			if manual:
				show_label(worktime)
			await play_wait(anim_work)
			Global.add_loyalty(satiety, duration)
			if manual:
				worktime -= 1
				set_label_count(worktime)

	running = false
	rest(manual and worktime == 0)
