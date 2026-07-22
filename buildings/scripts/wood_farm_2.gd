@tool
extends FarmsClass
var world_grid : WorldGrid
var animation_speed: float = 1.0

@onready var animation_player: AnimationPlayer = $Farm_Tree_lvl2_Full/AnimationPlayer

func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid

	if !is_ghost:
		pass
	animation_player.play(&"Anim_Farm_Tree_lvl2|Idle",-1,animation_speed)

func on_click_harvest():
	worktime = 6
	if !animation_player.is_playing() or animation_player.current_animation != &"Anim_Farm_Tree_lvl2|Work":
		_process_queue()

func _process_queue() -> void:
	while worktime > 0:
		animation_player.play(&"Anim_Farm_Tree_lvl2|Work", -1, animation_speed)
		await animation_player.animation_finished
		storage[&"wood_out"].put(Global.get_type("wood"), 9 * coefficient)
		worktime-=1
		if worktime == 0:
			animation_player.play(&"Anim_Farm_Tree_lvl2|Sleep",-1,animation_speed)
			await animation_player.animation_finished
			animation_player.play(&"Anim_Farm_Tree_lvl2|Sleep_Idle",-1,animation_speed)
