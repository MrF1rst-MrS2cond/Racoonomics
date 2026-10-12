@tool
extends KitchenBase


func _init() -> void:
	player_path = ^"kitchen_lvl2_full/AnimationPlayer"
	portion = 18
	anim_start = &"Rig_Rabbit_001|Sleep"
	anim_idle = &"Rig_Rabbit_001|Idle"
	anim_work = &"Rig_Rabbit_001|Work"
	anim_sleep = &"Rig_Rabbit_001|Sleep"
	anim_sleep_idle = &"Rig_Rabbit_001|Sleep_Idle"
