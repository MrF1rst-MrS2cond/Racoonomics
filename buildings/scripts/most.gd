@tool
class_name Bridge
extends Building

var world_grid : WorldGrid

func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid
	if !is_ghost:
		pass
