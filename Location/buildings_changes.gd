extends Node

@export var camera: Camera3D

var selected_build: Building

@onready var world_grid: WorldGrid = $"../WorldGrid"
@onready var build_mode_controller: Node = $"../BuildModeController"
@onready var main_ui: Control = %Main_UI

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("Info") and !build_mode_controller.current_ghost:
		var cell = _hovered_cell()
		var building = world_grid.get_building_at_cell(cell)
		if building is Building:
			build_desc_open(building)
	if event.is_action_released("Farm") and !build_mode_controller.current_ghost:
		var cell = _hovered_cell()
		var building = world_grid.get_building_at_cell(cell)
		if building is AppleFarm:
			building.on_click_AppleFarm()

func build_desc_open(build: Building):
	selected_build = build as Building
	var definition = load(selected_build.definition_paths)
	main_ui.info_current_building = build as Building
	main_ui.openDescription(definition)


func _hovered_cell() -> Vector2i:
	var viewport := get_viewport()
	var mouse_pos := viewport.get_mouse_position()

	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_direction := camera.project_ray_normal(mouse_pos)

	var target := -ray_origin.y / ray_direction.y
	var intersection := ray_origin + ray_direction * target

	return world_grid.world_to_cell(intersection)
