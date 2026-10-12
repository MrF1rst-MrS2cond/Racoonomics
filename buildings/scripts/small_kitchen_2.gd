@tool
class_name SmallKitchenLvl2
extends KitchenBase


func _init() -> void:
	player_path = ^"kitchen_lvl3_full/AnimationPlayer"
	manual = false
	portion = 36
	anim_start = &"Armature|Lvl3_idle"
	anim_idle = &"Armature|Lvl3_idle"
	anim_work = &"Armature|Lvl3_work"
