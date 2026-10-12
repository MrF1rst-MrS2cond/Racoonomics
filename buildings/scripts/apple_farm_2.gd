@tool
extends FarmsClass


func _init() -> void:
	level = 2
	item_id = &"apples"
	player_path = ^"Farm_Apple_lvl2_full/AnimationPlayer"
	anim_idle = &"Anim_Farm_Apple_lvl2|Idle"
	anim_work = &"Anim_Farm_Apple_lvl2|Work"
	anim_sleep = &"Anim_Farm_Apple_lvl2|Sleep"
	anim_sleep_idle = &"Anim_Farm_Apple_lvl2|Sleep_idle"
