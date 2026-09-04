@tool
extends FarmsClass

var label_scene: PackedScene = preload("res://UI/scenes/clikfarm.tscn")
var current_label: Node3D = null

var world_grid : WorldGrid
var animation_speed: float = 1.0

@onready var animation_player: AnimationPlayer = $Farm_Apple_lvl2_full/AnimationPlayer


func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid

	if !is_ghost:
		pass
	animation_player.play(&"Anim_Farm_Apple_lvl2|Idle", -1, animation_speed)


func on_click_harvest():
	worktime = 12

	_ensure_click_label()

	_update_label_count()

	if !animation_player.is_playing() or animation_player.current_animation != &"Anim_Farm_Apple_lvl2|Work":
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
		current_label.set_count(worktime)


func _process_queue() -> void:
	while worktime > 0:
		animation_player.play(&"Anim_Farm_Apple_lvl2|Work", -1, animation_speed)
		await animation_player.animation_finished
		storage[&"apples_out"].put(Global.get_type("apples"), 9 * coefficient)
		worktime -= 1

		_update_label_count()

		if worktime == 0:
			if is_instance_valid(current_label):
				current_label.queue_free()
				current_label = null

			animation_player.play(&"Anim_Farm_Apple_lvl2|Sleep", -1, animation_speed)
			await animation_player.animation_finished
			animation_player.play(&"Anim_Farm_Apple_lvl2|Sleep_idle", -1, animation_speed)


func _exit_tree() -> void:
	if is_instance_valid(current_label):
		current_label.queue_free()
