@tool
extends FarmsClass


func _init() -> void:
	level = 1
	item_id = &"apples"
	player_path = ^"Anim_Farm_Apple_lvl1/Anim_Farm_Apple_lvl1/AnimationPlayer"
	anim_idle = &"Anim_Farm_Apple_lvl1|Anim_Farm_Apple_lvl1|AppleIdle"
	anim_work = &"Anim_Farm_Apple_lvl1|Anim_Farm_Apple_lvl1|AppleTaking"
