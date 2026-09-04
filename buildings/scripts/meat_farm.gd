@tool
extends FarmsClass

var label_scene: PackedScene = preload("res://UI/scenes/clikfarm.tscn")
var current_label: Node3D = null

var world_grid : WorldGrid
var animation_speed: float = 1.0

@onready var animation_player: AnimationPlayer = $meat_farm_lvl1/AnimationPlayer


func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid

	if !is_ghost:
		pass


func on_click_harvest():
	click_queue += 1

	_ensure_click_label()

	_update_label_count()

	if !animation_player.is_playing() or animation_player.current_animation != &"Anim_Farm_Meat_lvl1|Action_001":
		_process_queue()


func _ensure_click_label() -> void:
	if is_ghost or Engine.is_editor_hint():
		return

	if is_instance_valid(current_label):
		return

	current_label = label_scene.instantiate() as Node3D
	current_label.building_owner = self

	get_tree().current_scene.add_child(current_label)

	if current_label.has_method("update_label_position"):
		current_label.update_label_position()


func _update_label_count() -> void:
	if is_instance_valid(current_label) and current_label.has_method("set_count"):
		current_label.set_count(click_queue)


func _process_queue() -> void:
	while click_queue > 0:
		animation_player.play(&"Anim_Farm_Meat_lvl1|Action_001", -1, animation_speed)
		await animation_player.animation_finished
		storage[&"meat_out"].put(Global.get_type("meat"), 9)
		click_queue -= 1

		_update_label_count()

	if is_instance_valid(current_label):
		current_label.queue_free()
		current_label = null


func _exit_tree() -> void:
	if is_instance_valid(current_label):
		current_label.queue_free()
