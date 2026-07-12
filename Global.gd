extends Node

@export var type_lookup : Dictionary[StringName, ItemType]
var loyalty : int

signal update_bar(int)
signal money_value_changed(new_value:int)

func _ready() -> void:
	var types_dir := DirAccess.open("res://resources/item_types")
	if !types_dir:
		push_error("item type lookup population failed, could not open directory")
		return

	types_dir.list_dir_begin()
	var file_name := types_dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var type := ResourceLoader.load("res://resources/item_types/" + file_name) as ItemType
			if type:
				type_lookup[type.id] = type
			else:
				push_warning("failed to load item type from file: " + file_name)
		file_name = types_dir.get_next()

func get_type(id: StringName) -> ItemType:
	return type_lookup.get(id, null)


func add_loyalty(loyalty_: int) -> void:
	loyalty += loyalty_
	await get_tree().create_timer(9.0).timeout
	loyalty -= loyalty_
	update_bar.emit(loyalty)
