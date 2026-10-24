class_name ItemStorage
extends Resource
signal item_added(slot_name: StringName)
@export var capacity: int = 2000000000000000000
@export var filter: ItemFilter

@export_category("Runtime state (don't edit)")
@export var stacks : Dictionary[StringName, int]

var _filled := -1 # сумма предметов, -1 = пересчитать

func get_filled_capacity() -> int:
	if _filled < 0:
		_filled = 0
		for quantity in stacks.values():
			_filled += quantity

	return _filled

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
	if can_store <= 0:
		return quantity

	stacks[type.id] = get_type_count(type) + can_store
	_filled += can_store
	item_added.emit(type.id)

	return quantity - can_store

func take(type: ItemType, quantity: int) -> int:
	return take_id(type.id, quantity)

# Единственное место, где предметы убывают
func take_id(id: StringName, quantity: int) -> int:
	var have : int = stacks.get(id, 0)
	var can_take := mini(have, quantity)

	if can_take > 0 and _filled >= 0:
		_filled -= can_take

	if have - can_take > 0:
		stacks[id] = have - can_take
	else:
		stacks.erase(id)

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

func auto_receive_from(source: ItemStorage, cap := Vector2i.MAX.x) -> int:
	var can_take := source.take_filtered(filter, mini(get_available_capacity(), cap))
	var total_taken := 0

	for type_id in can_take.keys():
		var type : ItemType = Global.get_type(type_id)
		put(type, can_take[type_id])
		total_taken += can_take[type_id]

	return total_taken
