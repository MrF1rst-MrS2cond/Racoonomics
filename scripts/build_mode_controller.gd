extends Node

@export var buildings : Array[BuildingDefinition]
@export var pipes : Array[BuildingDefinition] # по порядку: прямая, левая, правая
@export var select_color := Color(1, 0.2, 0.2, 0.4) # область удаления

@export var grid : WorldGrid
@export var camera : Camera3D
@onready var main_ui: Control = %Main_UI

@export var building_ghost_material : ShaderMaterial

@export_category("Runtime state (don't edit)")
@export var current_building : BuildingDefinition = null

@onready var post_process_quad: MeshInstance3D = $PostProcessQuad
@onready var edit_mode_transition: AnimationPlayer = $EditModeTransition
@onready var money_manager: Node = $"../MoneyManager"
@onready var building_selector: OptionButton = $DevButtonPrompt/BuildingSelector

var selected_building_index := 0
var current_ghost : Building
var current_grid_pos : Vector2i
var current_rotation := 0
var current_rotation_score := 0
var is_manual_rotation := false
var is_ports_warning := false

const DIRS : Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
var dragging := false
var drag_path : Array[Vector2i] = []
var drag_ghosts : Array[Building] = []
var drag_defs : Array[BuildingDefinition] = []
var drag_valid_count := 0 # сколько клеток с начала можно строить

var selecting := false # выделение области на удаление
var sel_start := Vector2i.ZERO
var sel_rect := Rect2i()
var sel_mesh : MeshInstance3D

func _ready() -> void:
	for building_def in buildings:
		building_selector.add_item(building_def.title)

func _process(_delta: float) -> void:
	if !current_building or !current_ghost:
		return

	if selecting:
		_update_selection()
		return

	var mouse_grid_pos := _hovered_cell()

	if mouse_grid_pos != current_grid_pos:
		current_grid_pos = mouse_grid_pos

		if dragging:
			_extend_path(current_grid_pos)
			return

		var best_rotation := calculate_best_rotation(current_grid_pos, current_building, current_rotation)
		if !is_manual_rotation:
			if best_rotation != current_rotation:
				current_rotation = best_rotation
				_refresh_ghost()
		else:
			is_manual_rotation = false

		current_ghost.origin_cell = current_grid_pos

		var is_valid := grid.get_overlap_with_clearance(
	Rect2i(current_ghost.origin_cell, current_building.dimensions), 
	current_building.clearance, 
	current_ghost
).is_empty()
		current_ghost.set_override_property("is_valid", is_valid)

		_detect_port_conflicts()

func enter_build_mode(building_def: BuildingDefinition) -> void:
	_cancel_drag()
	_cancel_select()
	if !current_building:
		edit_mode_transition.stop()
		edit_mode_transition.play("enter")
	current_building = building_def
	_refresh_ghost()

func _refresh_ghost() -> void:
	if current_ghost:
		current_ghost.queue_free()

	current_ghost = current_building.get_building_instance(current_rotation)
	current_ghost.origin_cell = current_grid_pos
	current_ghost.set_material_override(building_ghost_material)
	current_ghost.set_override_property("is_valid", true)
	current_ghost.is_ghost = true

	grid.add_child(current_ghost, OS.has_feature("editor"))

func exit_build_mode() -> void:
	_cancel_drag()
	_cancel_select()
	current_building = null
	edit_mode_transition.stop()
	edit_mode_transition.play("exit")
	current_grid_pos = Vector2i.ZERO
	if current_ghost:
		current_ghost.queue_free()
		current_ghost = null

func _mouse_cell() -> Vector2i:
	var viewport := get_viewport()
	var mouse_pos := viewport.get_mouse_position()

	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_direction := camera.project_ray_normal(mouse_pos)

	var target := -ray_origin.y / ray_direction.y
	var intersection := ray_origin + ray_direction * target

	return grid.world_to_cell(intersection)

func _hovered_cell() -> Vector2i:
	return _mouse_cell() - Vector2i((current_ghost.dimensions / 2.0).floor())

func _try_place_building() -> void:
	if !current_building or !current_ghost:
		return
	if _place(current_building, current_rotation, current_grid_pos):
		_refresh_ui()

func _place(def: BuildingDefinition, rot: int, cell: Vector2i) -> bool:
	if !money_manager.check_cost(def.purchase_cost):
		return false

	var placed_building = def.get_building_instance(rot)
	placed_building.origin_cell = cell

	if !grid.try_place_building(placed_building):
		placed_building.queue_free()
		money_manager.money += def.purchase_cost # возврат
		return false

	if placed_building.has_method(&"setup_building"):
		placed_building.setup_building(grid)
	return true

func _refresh_ui() -> void:
	if main_ui and main_ui.has_method("refresh_unlocked_buildings"):
		main_ui.refresh_unlocked_buildings()

func _unhandled_input(event: InputEvent) -> void:
	if !current_building or selecting:
		return
	if event.is_action_pressed("place_building"):
		if _is_pipe(current_building):
			dragging = true
			drag_path.clear()
			drag_path.append(current_grid_pos)
		else:
			_try_place_building()
	if event.is_action_pressed("rotate_building") and !dragging:
		current_rotation = (current_rotation + 1) % 4
		_refresh_ghost()
		current_grid_pos = Vector2i.ZERO
		is_manual_rotation = true

func _input(event: InputEvent) -> void: # отпускание над UI тоже ловим
	if dragging and event.is_action_released("place_building"):
		_finish_drag()
	if current_building and !dragging and event.is_action_pressed("quick_sell"):
		_start_select()
		get_viewport().set_input_as_handled() # чтобы кнопки UI не нажались
	elif selecting and event.is_action_released("quick_sell"):
		_finish_select()

func _on_building_selected(index: int) -> void:
	selected_building_index = index
	if current_building:
		enter_build_mode(buildings[selected_building_index])

func calculate_best_rotation(target_cell: Vector2i, definition: BuildingDefinition, manual_rotation: int) -> int:
	var best_rotation := manual_rotation
	var best_score := -1

	for rot in range(4):
		var score := _port_matches(target_cell, definition, rot) - 1
		if score > best_score:
			best_score = score
			best_rotation = rot

	return best_rotation

func _detect_port_conflicts() -> void:
	if !current_building or !current_ghost:
		return

	is_ports_warning = false

	for port in current_building.ports:
		var rotated_offset := current_building.rotate_cell(port.cell_offset, current_rotation, current_building.dimensions)
		var rotated_facing := current_building.rotate_facing(port.facing, current_rotation)

		var port_world_cell := current_grid_pos + rotated_offset
		var port_facing_cell := port_world_cell + port.get_facing_vector(rotated_facing)

		var adjacent_building := grid.get_building_at_cell(port_facing_cell)
		if adjacent_building and adjacent_building is Building:
			var adjacent_port := adjacent_building.get_port(port_facing_cell, port_world_cell) as BuildingPort
			if adjacent_port and port.type == adjacent_port.type:
				is_ports_warning = true
				current_ghost.set_override_property("is_warning", true)
				return

	current_ghost.set_override_property("is_warning", false)

func _port_matches(target_cell: Vector2i, definition: BuildingDefinition, rot: int) -> int:
	var matches := 0
	for port in definition.ports:
		var rotated_offset := definition.rotate_cell(port.cell_offset, rot, definition.dimensions)
		var rotated_facing := definition.rotate_facing(port.facing, rot)

		var port_world_cell := target_cell + rotated_offset
		var port_facing_cell := port_world_cell + port.get_facing_vector(rotated_facing)

		var adjacent_building := grid.get_building_at_cell(port_facing_cell)
		if adjacent_building and adjacent_building is Building:
			var adjacent_port := adjacent_building.get_port(port_facing_cell, port_world_cell) as BuildingPort
			if adjacent_port and port.type != adjacent_port.type:
				matches += 1
	return matches

# --- Протяжка труб ---

func _is_pipe(def: BuildingDefinition) -> bool:
	for pipe in pipes:
		if pipe.building_scene == def.building_scene: # по сцене, ресурсы-копии равны
			return true
	return false

func _extend_path(target: Vector2i) -> void:
	var last: Vector2i = drag_path.back()
	while last != target:
		var step := target - last
		if absi(step.x) >= absi(step.y):
			last += Vector2i(signi(step.x), 0)
		else:
			last += Vector2i(0, signi(step.y))
		var idx := drag_path.rfind(last)
		if idx >= 0:
			drag_path.resize(idx + 1) # возврат назад
		else:
			drag_path.append(last)
	_update_drag()

func _update_drag() -> void:
	_free_drag_ghosts()
	if drag_path.size() < 2:
		return
	current_ghost.hide()

	var budget: int = money_manager.money
	var ok := true # после первой ошибки дальше нельзя
	var count := drag_path.size()
	for i in count:
		var d_in := DIRS.find(drag_path[i] - drag_path[i - 1]) if i > 0 else -1
		var d_out := DIRS.find(drag_path[i + 1] - drag_path[i]) if i < count - 1 else -1
		var pick := _best_pipe(drag_path[i], d_in, d_out)
		if pick.is_empty():
			break

		var def: BuildingDefinition = pick[0]
		var ghost := def.get_building_instance(pick[1])
		ok = ok and def.purchase_cost <= budget and grid.get_overlap_with_clearance(
				Rect2i(drag_path[i], ghost.dimensions), def.clearance, ghost).is_empty()
		if ok:
			budget -= def.purchase_cost
			drag_valid_count += 1

		ghost.set_material_override(building_ghost_material)
		ghost.set_override_property("is_valid", ok)
		ghost.is_ghost = true
		grid.add_child(ghost, OS.has_feature("editor"))
		ghost.origin_cell = drag_path[i] # позиция ставится только в дереве
		drag_ghosts.append(ghost)
		drag_defs.append(def)

## Подбор трубы для клетки. d_in/d_out: направление потока, -1 - любое
func _best_pipe(cell: Vector2i, d_in: int, d_out: int) -> Array:
	var best := []
	var best_score := -1
	for def in pipes:
		for rot in 4:
			var flow := _flow(def, rot)
			if (d_in >= 0 and flow.x != d_in) or (d_out >= 0 and flow.y != d_out):
				continue
			var score := _port_matches(cell, def, rot) # концы липнут к зданиям
			if score > best_score:
				best_score = score
				best = [def, rot]
	return best

## Направления потока трубы: x - откуда входит, y - куда выходит
func _flow(def: BuildingDefinition, rot: int) -> Vector2i:
	var flow := Vector2i(-1, -1)
	for port in def.ports:
		var facing := def.rotate_facing(port.facing, rot)
		if port.type == BuildingPort.PortType.IMPORTS:
			flow.x = (facing + 2) % 4
		else:
			flow.y = facing
	return flow

func _finish_drag() -> void:
	dragging = false
	if drag_path.size() < 2:
		_try_place_building() # просто клик
	else:
		var placed := false
		for i in drag_valid_count:
			if _place(drag_defs[i], drag_ghosts[i].rotation_steps, drag_path[i]):
				placed = true
		if placed:
			_refresh_ui()
	_cancel_drag()

func _free_drag_ghosts() -> void:
	for ghost in drag_ghosts:
		ghost.queue_free()
	drag_ghosts.clear()
	drag_defs.clear()
	drag_valid_count = 0

func _cancel_drag() -> void:
	dragging = false
	drag_path.clear()
	_free_drag_ghosts()
	if current_ghost:
		current_ghost.show()

# --- Удаление областью ---

func _start_select() -> void:
	selecting = true
	sel_start = _mouse_cell()
	if !sel_mesh:
		sel_mesh = MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2.ONE
		sel_mesh.mesh = plane
		var mat := StandardMaterial3D.new()
		mat.albedo_color = select_color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.render_priority = 5 # после постпроцесса, как у призрака
		mat.no_depth_test = true # поверх рельефа
		sel_mesh.material_override = mat
		grid.add_child(sel_mesh)
	sel_mesh.show()
	if current_ghost:
		current_ghost.hide()
	_update_selection()

func _update_selection() -> void:
	var end := _mouse_cell()
	var top_left := Vector2i(mini(sel_start.x, end.x), mini(sel_start.y, end.y))
	sel_rect = Rect2i(top_left, (sel_start - end).abs() + Vector2i.ONE)
	var size := Vector2(sel_rect.size) * grid.cell_size
	sel_mesh.scale = Vector3(size.x, 1, size.y)
	sel_mesh.position = grid.cell_to_world(top_left) + Vector3(size.x * 0.5, 0.1, size.y * 0.5)

func _finish_select() -> void:
	for building in grid.buildings_cache.duplicate():
		if !(building is Hub or building is Bridge) and Rect2i(building.origin_cell, building.dimensions).intersects(sel_rect):
			_sell(building)
	_cancel_select()

func _sell(building: Building) -> void:
	if building.definition_paths != "" and ResourceLoader.exists(building.definition_paths):
		money_manager.money += (load(building.definition_paths) as BuildingDefinition).purchase_cost
	grid.buildings_cache.erase(building)
	grid._free_rect(Rect2i(building.origin_cell, building.dimensions))
	if main_ui.info_current_building == building:
		main_ui.info_current_building = null
		main_ui.closeDescription()
	building.queue_free()

func _cancel_select() -> void:
	selecting = false
	if sel_mesh:
		sel_mesh.hide()
	if current_ghost:
		current_ghost.show()
