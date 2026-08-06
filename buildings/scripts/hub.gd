extends Start
class_name Hub
signal level_changed(new_level: int)

var world_grid : WorldGrid
@export var Hublevel: int = 1:
	set(value):
		Hublevel = value
		level_changed.emit(Hublevel)

func _ready() -> void:
	super() 
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid
	var main_ui = get_tree().current_scene.find_child("Main_UI", true, false)
	if main_ui and main_ui.has_method("refresh_unlocked_buildings"):
		main_ui.refresh_unlocked_buildings()
