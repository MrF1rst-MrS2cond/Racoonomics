@tool
class_name WorldGrid
extends Node3D

@export var cell_size := Vector2.ONE

@export_category("Runtime state (don't edit)")
@export var region_bounds : Array[Rect2i]
@export var occupied_bounds : Array[Rect2i]
@export var draw_grid := false

@export_group("Starter Buildings")
## Спавним только Hub, зоны стран размещаются как GridRegion в сцене!
@export var starter_scenes: Array[PackedScene] = [
	preload("res://buildings/scenes/Hub.tscn")
]
@export var starter_cells: Array[Vector2i] = [
	Vector2i(3, 0)
]

var valid_cells : Dictionary[Vector2i, bool]
var occupied_cells : Dictionary[Vector2i, Node]
var buildings_cache : Array[Building]
var process_tick_step := 0
var total_steps := 0


func world_to_cell(world_pos: Vector3) -> Vector2i:
	var relative_pos : Vector3 = world_pos - global_position
	return Vector2i(floori(relative_pos.x / cell_size.x), floori(relative_pos.z / cell_size.y))


func cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * cell_size.x, 0, cell.y * cell_size.y)


## Возвращает CountryZone, к которому принадлежит ячейка
func _get_country_zone_at_cell(cell: Vector2i) -> CountryZone:
	for child in get_children():
		if child is CountryZone:
			var zone := child as CountryZone
			if zone.contains(cell):
				return zone
	return null


func _get_bridge_region_at_cell(cell: Vector2i) -> BridgeRegion:
	for child in get_children():
		if child is BridgeRegion:
			var bridge_region := child as BridgeRegion
			if bridge_region.contains(cell):
				return bridge_region
	return null


func _occupy_rect(rect: Rect2i, object: Node) -> void:
	occupied_bounds.append(rect)
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			var cell = Vector2i(x, y)
			occupied_cells[cell] = object


func _free_rect(rect: Rect2i) -> void:
	occupied_bounds.erase(rect)
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			var cell = Vector2i(x, y)
			occupied_cells.erase(cell)


func get_overlap(rect: Rect2i) -> Array[Vector2i]:
	var overlap_cells : Array[Vector2i] = []
	for x in range(0, rect.size.x):
		for y in range(0, rect.size.y):
			var cell := rect.position + Vector2i(x, y)
			if !valid_cells.has(cell) or occupied_cells.has(cell):
				overlap_cells.append(Vector2i(cell))
	return overlap_cells


## Проверка разрешений строительства
func get_overlap_with_clearance(rect: Rect2i, clearance: int, placement_building: Building = null) -> Array[Vector2i]:
	var overlap_cells : Array[Vector2i] = []

	for x in range(rect.size.x):
		for y in range(rect.size.y):
			var cell := rect.position + Vector2i(x, y)

			# 1. Проверяем наличие ячейки в пределах доступных регионов
			if !valid_cells.has(cell):
				overlap_cells.append(cell)
				continue

			var bridge_region := _get_bridge_region_at_cell(cell)
			var country_zone := _get_country_zone_at_cell(cell)

			# 2. Правила постройки в зоне Моста (BridgeRegion)
			if bridge_region != null:
				if not bridge_region.permission_to_build_for_bridge():
					overlap_cells.append(cell)
					continue
				
				# В зоне моста МОЖНО строить ТОЛЬКО сам Мост
				if not (placement_building is Bridge):
					overlap_cells.append(cell)
					continue

			# 3. Правила постройки в зонах стран (CountryZone)
			elif country_zone != null:
				if not country_zone.permission_to_build():
					overlap_cells.append(cell)
					continue

				# Мост НЕЛЬЗЯ строить внутри обычных зон стран
				if placement_building is Bridge:
					overlap_cells.append(cell)
					continue

				var is_store := (placement_building is Store) or (placement_building is StoreLvl3)
				var is_pipe := ("Pipe" in placement_building.get_class() or placement_building.name.begins_with("Pipe"))
				
				if not (is_store or is_pipe):
					overlap_cells.append(cell)
					continue
			else:
				# На нейтральной земле НЕЛЬЗЯ строить Store и Bridge
				if (placement_building is Store) or (placement_building is StoreLvl3) or (placement_building is Bridge):
					overlap_cells.append(cell)
					continue

			# 4. Проверка занятости клетки зданиями
			if occupied_cells.has(cell):
				overlap_cells.append(cell)

	# 5. Проверка клиренса между строящимся и существующими зданиями
	for building in buildings_cache:
		if !is_instance_valid(building) or building == placement_building:
			continue

		var effective_clearance := mini(clearance, building.clearance)
		var expanded := Rect2i(building.origin_cell, building.dimensions).grow(effective_clearance)

		if expanded.intersects(rect):
			overlap_cells.append(building.origin_cell)

	return overlap_cells


func set_draw_grid(value: bool) -> void:
	for child in get_children():
		if child is GridRegion:
			var region = child as GridRegion
			region.set_highlight_grid(value)


func get_building_at_cell(cell: Vector2i) -> Node:
	if occupied_cells.has(cell) and occupied_cells[cell].is_inside_tree():
		return occupied_cells[cell]
	return null


func try_place_building(building: Building) -> bool:
	if !get_overlap_with_clearance(Rect2i(building.origin_cell, building.dimensions), building.clearance, building).is_empty():
		return false

	var building_rect = Rect2i(building.origin_cell, building.dimensions)
	_occupy_rect(building_rect, building)

	buildings_cache.append(building)
	building.is_active = true

	if building.get_parent() != self:
		add_child(building)
		building.update_position()

	if building.has_method(&"setup_building"):
		building.setup_building(self)

	return true


func replace_building(current_building: Building, new_building: Building) -> bool:
	if buildings_cache.has(current_building) and is_instance_valid(current_building):
		var current_building_rect := Rect2i(current_building.origin_cell, current_building.dimensions)
		_free_rect(current_building_rect)
		buildings_cache.erase(current_building)

		current_building.queue_free()

		return try_place_building(new_building)

	return false


func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	for child in get_children():
		if child is GridRegion:
			var region = child as GridRegion
			region_bounds.append(region.get_bounds())
			for cell in region.get_cells():
				valid_cells[cell] = true
				
	_spawn_starter_buildings()


func _spawn_starter_buildings() -> void:
	var spawn_count := mini(starter_scenes.size(), starter_cells.size())
	for i in range(spawn_count):
		var building_scene := starter_scenes[i]
		var target_cell := starter_cells[i]
		if not building_scene:
			continue
		var new_building = building_scene.instantiate() as Building
		if new_building:
			new_building.origin_cell = target_cell
			var is_placed := try_place_building(new_building)
			if is_placed:
				print("Стартовое здание успешно установлено в: ", target_cell)
			else:
				new_building.queue_free()


func _physics_process(_delta: float) -> void:
	if Engine.get_physics_frames() % 2:
		return

	var indices_to_remove : Array[int] = []

	for building in buildings_cache:
		if !is_instance_valid(building):
			indices_to_remove.append(buildings_cache.find(building))
			continue

		if !building.is_inside_tree() or !building.is_active:
			continue

		match process_tick_step:
			0: building.tick_produce(total_steps)
			1: building.tick_transport()
			2: building.tick_consume(total_steps)

	for i in range(indices_to_remove.size() - 1, -1, -1):
		var index = indices_to_remove[i]
		buildings_cache.remove_at(index)

	process_tick_step = (process_tick_step + 1) % 3
	total_steps += 1
