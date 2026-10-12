@tool
extends FarmsClass


func _init() -> void:
	level = 2
	item_id = &"meat"
	player_path = ^"meat_farm_lvl2/AnimationPlayer"
	anim_idle = &"Anim_Farm_Meat_lvl2|Anim_farm_lvl2_IDLE"
	anim_work = &"Anim_Farm_Meat_lvl2|Anim_farm_lvl2_work"
	anim_sleep = &"Anim_Farm_Meat_lvl2|Anim_farm_lvl2_sleep"
	anim_sleep_idle = &"Anim_Farm_Meat_lvl2|Anim_farm_lvl2_IDLE_SLEEP"
