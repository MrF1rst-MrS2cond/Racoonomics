@tool
extends FarmsClass
var world_grid : WorldGrid
var animation_speed: float = 1.0

@onready var animation_player: AnimationPlayer = $Farm_Tree_lvl3_Full/AnimationPlayer

func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid

	if !is_ghost:
		pass
	animation_player.play(&"Armature|Wood_idle",-1,animation_speed)

func on_click_harvest():
	if !animation_player.is_playing() or animation_player.current_animation != &"Armature|Wood_Work":
		_process_queue()
#	if not animation_player.current_animation():
#		_process_queue()


func _process_queue() -> void:
	animation_player.play(&"Armature|Wood_Work", -1, animation_speed)
	await animation_player.animation_finished
	storage[&"wood_out"].put(Global.get_type("wood"), 9 * coefficient * coefficient)
	_process_queue()
