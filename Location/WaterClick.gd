extends StaticBody3D

@export var vfx_animation_scene: PackedScene

func _input_event(camera: Camera3D, event: InputEvent, _click_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.is_echo():
		var main_ui = get_tree().current_scene.find_child("Main_UI", true, false)
		if main_ui and main_ui.has_method("is_in_build_mode") and main_ui.is_in_build_mode():
			return
		
		var mouse_pos = event.position
		var ray_from = camera.project_ray_origin(mouse_pos)
		var ray_dir = camera.project_ray_normal(mouse_pos)
		var water_y = global_position.y
		
		if abs(ray_dir.y) < 0.001:
			return
			
		var t = (water_y - ray_from.y) / ray_dir.y
		if t < 0:
			return
			
		var hit_point = ray_from + ray_dir * t
		spawn_vfx_animation(hit_point)

func spawn_vfx_animation(pos: Vector3) -> void:
	if not vfx_animation_scene:
		return
		
	var vfx = vfx_animation_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(vfx)
	vfx.global_position = pos
	vfx.global_position.y += 1.0
