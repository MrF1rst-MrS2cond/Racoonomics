@tool
extends Building
class_name AppleFarm
var world_grid : WorldGrid
var click_queue: int = 0
#var produce_buffer := 0
var animation_speed: float = 1.0

@onready var animation_player: AnimationPlayer = $Anim_Farm_Apple_lvl1/Anim_Farm_Apple_lvl1/AnimationPlayer


func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid

	if !is_ghost:
		pass
		#animation_player.play(&"Anim_Farm_Apple_lvl1|Anim_Farm_Apple_lvl1|AppleTaking", -1, animation_speed)

#func on_click_AppleFarm():
#	animation_player.play(&"Anim_Farm_Apple_lvl1|Anim_Farm_Apple_lvl1|AppleTaking", -1, animation_speed)
#	await animation_player.animation_finished
#	storage[&"apples_out"].put(Global.get_type("apples"), 5)

func on_click_AppleFarm():
	click_queue += 1
	if not animation_player.is_playing():
		_process_queue()


func _process_queue() -> void:
	while click_queue > 0:
		animation_player.play(&"Anim_Farm_Apple_lvl1|Anim_Farm_Apple_lvl1|AppleTaking", -1, animation_speed)
		await animation_player.animation_finished
		storage[&"apples_out"].put(Global.get_type("apples"), 5)
		click_queue -= 1

#func _process_queue() -> void:
#	while click_queue > 0:
#		animation_player.play(&"Anim_Farm_Apple_lvl1|Anim_Farm_Apple_lvl1|AppleTaking", -1, animation_speed)
#		await animation_player.animation_finished
#		produce_buffer += 5
#		click_queue -= 1
#func tick_produce(tick: int) -> void:
#	if tick % 3 == 0:
#		pass
		#storage[&"apples_out"].put(Global.get_type("apples"), 5)
		
		

#func tick_produce(int) -> void:
#	if produce_buffer:
#		storage[&"apples_out"].put(Global.get_type("apples"), produce_buffer)
#		produce_buffer = 0
