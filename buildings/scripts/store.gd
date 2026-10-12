@tool
class_name Store
extends StoreBase


func _init() -> void:
	player_path = ^"Store_lvl2_full/AnimationPlayer"
	portion = 18
	anim_start = &"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Sleep_idle"
	anim_idle = &"Rig_Rabbit|Idle"
	anim_work = &"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Work"
	anim_reject = &"Rig_Rabbit|Reject"
	anim_sleep = &"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Sleep"
	anim_sleep_idle = &"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Sleep_idle"
