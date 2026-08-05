@tool
class_name BridgeRegion
extends GridRegion

@export var required_hub_level := 5

var world_grid : WorldGrid

func _ready() -> void:
	super()
	if get_parent() is WorldGrid:
		world_grid = get_parent() as WorldGrid
	
	if not Engine.is_editor_hint():
		hide()

## Проверка: разблокирована ли зона Моста
func permission_to_build_for_bridge() -> bool:
	if not world_grid:
		world_grid = get_parent() as WorldGrid
		if not world_grid:
			return false

	for building in world_grid.buildings_cache:
		if is_instance_valid(building) and building is Hub:
			if building.Hublevel >= required_hub_level:
				if not is_visible_in_tree():
					show()
				return true

	if is_visible_in_tree():
		hide()
	return false
