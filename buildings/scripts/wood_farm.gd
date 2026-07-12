@tool
extends FarmsClass
var click_queue: int = 0
var animation_speed: float = 1.0

var world_grid : WorldGrid

@onready var animation_player: AnimationPlayer = $Anim_Farm_Tree_lvl1/AnimationPlayer


func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid

	if !is_ghost:
		pass
		#animation_player.play(&"Anim_Farm_Tree_lvl1|Anim_Tree_work_lvl1", -1, animation_speed)

func on_click_harvest():
	click_queue += 1
	if not animation_player.is_playing():
		_process_queue()


func _process_queue() -> void:
	while click_queue > 0:
		animation_player.play(&"Anim_Farm_Tree_lvl1|Anim_Tree_work_lvl1", -1, animation_speed)
		await animation_player.animation_finished
		storage[&"wood_out"].put(Global.get_type("wood"), 9)
		click_queue -= 1

#func tick_produce(tick: int) -> void:
#	if tick % 3 == 0:
#		storage[&"wood_out"].put(Global.get_type("wood"), 5)
#		#print("запас дерева ", storage[&"wood_out"].stacks)
