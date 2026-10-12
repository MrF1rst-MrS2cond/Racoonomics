@tool
extends FarmsClass


func _init() -> void:
	level = 1
	item_id = &"wood"
	player_path = ^"Farm_Tree_lvl1_Full/AnimationPlayer"
	anim_idle = &"Anim_Farm_Tree_lvl1|Idle"
	anim_work = &"Anim_Farm_Tree_lvl1|Anim_Farm_Tree_lvl1|Anim_Tree_work_lvl1"
