@tool
extends FarmsClass


func _init() -> void:
	level = 1
	item_id = &"nuts"
	player_path = ^"Anim_Farm_Oreh_lvl1/AnimationPlayer"
	anim_idle = &"Anim_Farm_Oreh_lvl1|Idle"
	anim_work = &"Anim_Farm_Oreh_lvl1|Take"
