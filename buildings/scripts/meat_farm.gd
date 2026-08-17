@tool
extends FarmsClass
var world_grid : WorldGrid
var animation_speed: float = 1.0

@onready var animation_player: AnimationPlayer = $meat_farm_lvl1/AnimationPlayer


func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid

	if !is_ghost:
		pass
	#animation_player.play(&"Anim_Farm_Apple_lvl1|Anim_Farm_Apple_lvl1|AppleIdle",-1,animation_speed)

func on_click_harvest():
	click_queue += 1
	if !animation_player.is_playing() or animation_player.current_animation != &"Anim_Farm_Meat_lvl1|Action_001":
		_process_queue()


func _process_queue() -> void:
	while click_queue > 0:
		animation_player.play(&"Anim_Farm_Meat_lvl1|Action_001", -1, animation_speed)
		await animation_player.animation_finished
		storage[&"meat_out"].put(Global.get_type("meat"), 9)
		click_queue -= 1
