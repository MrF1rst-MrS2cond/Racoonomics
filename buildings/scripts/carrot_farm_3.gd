@tool
extends FarmsClass


func _init() -> void:
	level = 3
	item_id = &"carrots"
	player_path = ^"Farm_Carrot_lvl3_Full/AnimationPlayer"
	anim_idle = &"Anim_Farm_Carrot_lvl3|Carrot_Idle"
	anim_work = &"Anim_Farm_Carrot_lvl3|Carrot_work"
