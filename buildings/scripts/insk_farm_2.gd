@tool
extends FarmsClass


func _init() -> void:
	level = 2
	item_id = &"flies"
	player_path = ^"Anim_farm_Insk_lvl2/AnimationPlayer"
	anim_idle = &"Anim_Farm_Insk_lvl2_001|Anim_Farm_Insk_lvl2_idle"
	anim_work = &"Anim_Farm_Insk_lvl2_001|Anim_Farm_Insk_lvl2_work"
	anim_sleep = &"Anim_Farm_Insk_lvl2_001|Anim_Farm_Insk_lvl2_sleep"
	anim_sleep_idle = &"Anim_Farm_Insk_lvl2_001|Anim_Farm_Insk_lvl2_sleep_idle"
