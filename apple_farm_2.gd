@tool
extends FarmsClass
var world_grid : WorldGrid
var click_queue: int = 0
var animation_speed: float = 1.0

@onready var animation_player: AnimationPlayer = $Anim_Farm_Apple_Sleep_lvl2_full/AnimationPlayer

func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid

	if !is_ghost:
		pass

func on_click_harvest():
	click_queue += 1
	if not animation_player.is_playing():
		_process_queue()


func _process_queue() -> void:
	while click_queue > 0:
		animation_player.play(&"Anim_Farm_Apple_lvl2|Anim_Farm_Apple_lvl2|Anim_Farm_Apple_lvl2", -1, animation_speed)
		await animation_player.animation_finished
		storage[&"apples_out"].put(Global.get_type("apples"), 9 * coefficient)
		click_queue -= 1
