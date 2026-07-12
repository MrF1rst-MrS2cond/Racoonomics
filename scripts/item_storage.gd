class_name ItemStorage
extends Resource
signal item_added(slot_name: StringName)
@export var capacity: int = 10
@export var filter: ItemFilter

@export_category("Runtime state (don't edit)")
@export var stacks : Dictionary[StringName, int]

func get_filled_capacity() -> int:
	var total := 0
	for quantity in stacks.values():
		total += quantity

	return total

func get_available_capacity() -> int:
	return capacity - get_filled_capacity()

func is_empty() -> bool:
	return get_filled_capacity() == 0

func is_full() -> bool:
	return get_filled_capacity() >= capacity

func get_type_count(type: ItemType) -> int:
	return stacks.get(type.id, 0)

func put(type: ItemType, quantity: int) -> int:
	if !filter.accepts(type):
		return quantity

	var can_store := mini(capacity - get_filled_capacity(), quantity)
	stacks[type.id] = get_type_count(type) + can_store
	
	if can_store > 0:
		item_added.emit(type.id)

	return quantity - can_store

func take(type: ItemType, quantity: int) -> int:
	var can_take := mini(get_type_count(type), quantity)
	stacks[type.id] = get_type_count(type) - can_take

	if stacks[type.id] <= 0:
		stacks.erase(type.id)

	return can_take

func take_filtered(filter_: ItemFilter, quantity: int) -> Dictionary[StringName, int]:
	var taken : Dictionary[StringName, int]
	var remaining := quantity

	for type_id in stacks.keys():
		if remaining <= 0:
			break

		var type : ItemType = Global.get_type(type_id)
		if filter_.accepts(type):
			var can_take := take(type, remaining)
			if can_take > 0:
				taken[type_id] = can_take
				remaining -= can_take

	return taken

func auto_receive_from(source: ItemStorage) -> void:
	var can_take := source.take_filtered(filter, get_available_capacity())

	for type_id in can_take.keys():
		var type : ItemType = Global.get_type(type_id)
		put(type, can_take[type_id])
