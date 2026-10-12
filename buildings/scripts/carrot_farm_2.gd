@tool
extends FarmsClass


func _init() -> void:
	level = 2
	item_id = &"carrots"
	player_path = ^"Farm_Carrot_lvl2_Full/AnimationPlayer"
	anim_idle = &"Anim_Farm_Carrot_lvl2|IDLE"
	anim_work = &"Anim_Farm_Carrot_lvl2|Taking"
	anim_sleep = &"Anim_Farm_Carrot_lvl2|Sleep"
	anim_sleep_idle = &"Anim_Farm_Carrot_lvl2|Sleep_Idle"
