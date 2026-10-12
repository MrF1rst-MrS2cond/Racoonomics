@tool
extends FarmsClass


func _init() -> void:
	level = 3
	item_id = &"apples"
	player_path = ^"Farm_Apple_lvl3_full/AnimationPlayer"
	anim_idle = &"Anim_Farm_Apple_lvl3_001|Apple_Idle"
	anim_work = &"Anim_Farm_Apple_lvl3_001|Apple_Work"
