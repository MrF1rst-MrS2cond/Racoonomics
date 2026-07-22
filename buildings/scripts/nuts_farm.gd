@tool
extends FarmsClass
var animation_speed: float = 1.0

var world_grid : WorldGrid

@onready var animation_player: AnimationPlayer = $Anim_Farm_Oreh_lvl1/AnimationPlayer

func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid

	if !is_ghost:
		pass
		#animation_player.play(&"Anim_Farm_Oreh_lvl1|Take", -1, animation_speed)
	animation_player.play(&"Anim_Farm_Oreh_lvl1|Idle", -1, animation_speed)
	

func on_click_harvest():
	click_queue += 1
	if !animation_player.is_playing() or animation_player.current_animation != &"Anim_Farm_Oreh_lvl1|Take":
		_process_queue()


func _process_queue() -> void:
	while click_queue > 0:
		animation_player.play(&"Anim_Farm_Oreh_lvl1|Take", -1, animation_speed)
		await animation_player.animation_finished
		storage[&"nuts_out"].put(Global.get_type("nuts"), 9)
		click_queue -= 1

#func tick_produce(tick: int) -> void:
#	if tick % 3 == 0:
#		storage[&"nuts_out"].put(Global.get_type("nuts"), 5)
