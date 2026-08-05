@tool
class_name WestRegion
extends GridRegion

var world_grid : WorldGrid

func _ready() -> void:
	super()
	if get_parent() is WorldGrid:
		world_grid = get_parent() as WorldGrid

func is_bridge_built() -> bool:
	if not world_grid:
		world_grid = get_parent() as WorldGrid
		if not world_grid:
			return false

	for building in world_grid.buildings_cache:
		if is_instance_valid(building) and building is Bridge:
			return true

	return false
