@tool
extends FarmsClass


func _init() -> void:
	level = 3
	item_id = &"wood"
	player_path = ^"Farm_Tree_lvl3_Full/AnimationPlayer"
	anim_idle = &"Armature|Wood_idle"
	anim_work = &"Armature|Wood_Work"
