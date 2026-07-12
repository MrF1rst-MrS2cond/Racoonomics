extends Node

@export var buildings : Array[BuildingDefinition]

@export var grid : WorldGrid
@export var camera : Camera3D

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

func _ready() -> void:
	for building_def in buildings:
		building_selector.add_item(building_def.title)

func _process(_delta: float) -> void:
	if !current_building or !current_ghost:
		return

	var mouse_grid_pos := _hovered_cell()

	if mouse_grid_pos != current_grid_pos:
		current_grid_pos = mouse_grid_pos

		var best_rotation := calculate_best_rotation(current_grid_pos, current_building, current_rotation)
		if !is_manual_rotation:
			if best_rotation != current_rotation:
				current_rotation = best_rotation
				_refresh_ghost()
		else:
			is_manual_rotation = false

		current_ghost.origin_cell = current_grid_pos

		var is_valid := grid.get_overlap_with_clearance(Rect2i(current_ghost.origin_cell, current_building.dimensions), current_building.clearance).is_empty()
		current_ghost.set_override_property("is_valid", is_valid)

		_detect_port_conflicts()

func enter_build_mode(building_def: BuildingDefinition) -> void:
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

	grid.add_child(current_ghost)

func exit_build_mode() -> void:
	current_building = null
	edit_mode_transition.stop()
	edit_mode_transition.play("exit")
	current_grid_pos = Vector2i.ZERO
	if current_ghost:
		current_ghost.queue_free()
		current_ghost = null

func _hovered_cell() -> Vector2i:
	var viewport := get_viewport()
	var mouse_pos := viewport.get_mouse_position()

	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_direction := camera.project_ray_normal(mouse_pos)

	var target := -ray_origin.y / ray_direction.y
	var intersection := ray_origin + ray_direction * target

	return grid.world_to_cell(intersection) - Vector2i((current_ghost.dimensions / 2.0).floor())

func _try_place_building() -> void:
	if !current_building or !current_ghost or !money_manager.check_cost(current_building.purchase_cost):
		return

	var placed_building = current_building.get_building_instance(current_rotation)
	placed_building.origin_cell = current_grid_pos

	if !grid.try_place_building(placed_building):
		placed_building.queue_free()
		money_manager.money += current_building.purchase_cost
	else:
		if placed_building.has_method(&"setup_building"):
			placed_building.setup_building(grid)
		#exit_build_mode()

func _unhandled_input(event: InputEvent) -> void:
	if !current_building:
		return
	if event.is_action_pressed("place_building"):
		_try_place_building()
	if event.is_action_pressed("rotate_building"):
		current_rotation = (current_rotation + 1) % 4
		_refresh_ghost()
		current_grid_pos = Vector2i.ZERO
		is_manual_rotation = true

func _on_building_selected(index: int) -> void:
	selected_building_index = index
	if current_building:
		enter_build_mode(buildings[selected_building_index])

func calculate_best_rotation(target_cell: Vector2i, definition: BuildingDefinition, manual_rotation: int) -> int:
	var best_rotation := manual_rotation
	var best_score := -1

	for rot in range(4):
		var score := -1

		for port in definition.ports:
			var rotated_offset := definition.rotate_cell(port.cell_offset, rot, definition.dimensions)
			var rotated_facing := definition.rotate_facing(port.facing, rot)

			var port_world_cell := target_cell + rotated_offset
			var port_facing_cell := port_world_cell + port.get_facing_vector(rotated_facing)

			var adjacent_building := grid.get_building_at_cell(port_facing_cell)
			if adjacent_building and adjacent_building is Building:
				var adjacent_port := adjacent_building.get_port(port_facing_cell, port_world_cell) as BuildingPort
				if adjacent_port and port.type != adjacent_port.type:
					score += 1

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
