@tool
class_name StoreLvl3
extends StoreBase


func _init() -> void:
	player_path = ^"Store_lvl3_full/AnimationPlayer"
	manual = false
	portion = 72
	anim_start = &"Rig_Rabbit_003|Store_Idle"
	anim_idle = &"Rig_Rabbit_003|Store_Idle"
	anim_work = &"Rig_Rabbit_003|Store_work"
	anim_reject = &"Rig_Rabbit_003|Reject"
