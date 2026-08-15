class_name BigRecipe
extends Resource

@export var input_a: ItemType
@export var input_b: ItemType
@export var result: ItemType

func matches(item_1: ItemType, item_2: ItemType) -> bool:
	if not item_1 or not item_2 or not input_a or not input_b:
		return false
	
	var match_direct := (item_1.id == input_a.id and item_2.id == input_b.id)
	var match_reversed := (item_1.id == input_b.id and item_2.id == input_a.id)
	
	return match_direct or match_reversed
