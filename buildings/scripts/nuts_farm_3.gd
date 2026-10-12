@tool
extends FarmsClass


func _init() -> void:
	level = 3
	item_id = &"nuts"
	player_path = ^"Farm_Oreh_lvl3_full/AnimationPlayer"
	anim_idle = &"Armature_001|Nuts_Idle"
	anim_work = &"Armature_001|Nuts_work"
