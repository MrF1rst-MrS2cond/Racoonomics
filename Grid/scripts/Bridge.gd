@tool
class_name BridgeRegion
extends GridRegion

@export var required_hub_level := 5

var world_grid : WorldGrid
var is_bridge_built := false

func _ready() -> void:
	super()
	if get_parent() is WorldGrid:
		world_grid = get_parent() as WorldGrid
	
	if not Engine.is_editor_hint():
		hide()
		# Подключаемся к сигналу Хаба после полной загрузки сцены
		call_deferred(&"_connect_to_hub")

# ==========================================
# 1. ОБНОВЛЕНИЕ МЕША И ШЕЙДЕРА (Плоская сетка)
# ==========================================

func _update_game_view() -> void:
	super()
	if game_grid_view and game_grid_view.mesh:
		var cell_size : Vector2 = world_grid.cell_size if world_grid else Vector2.ONE
		# Делаем меш плоским (высота Y = 0.0)
		game_grid_view.mesh.size = Vector3(size.x * cell_size.x, 0.0, size.y * cell_size.y)
		game_grid_view.position.y = 0.0 

func _editor_update_visualization() -> void:
	super()
	var grid = get_parent() as WorldGrid
	if grid and editor_visualizer and editor_visualizer.mesh:
		var cell_size : Vector2 = grid.cell_size
		editor_visualizer.mesh.size = Vector3(size.x * cell_size.x, 0.0, size.y * cell_size.y)
		editor_visualizer.position.y = 0.0

# ==========================================
# 2. РЕАКЦИЯ НА УРОВЕНЬ ХАБА (Сигналы)
# ==========================================

func _connect_to_hub() -> void:
	if not world_grid:
		return

	for building in world_grid.buildings_cache:
		if is_instance_valid(building) and building is Hub:
			var hub := building as Hub
			if not hub.level_changed.is_connected(_on_hub_level_changed):
				hub.level_changed.connect(_on_hub_level_changed)
			# Проверяем уровень прямо при запуске
			_on_hub_level_changed(hub.Hublevel)
			break

func _on_hub_level_changed(new_level: int) -> void:
	if is_bridge_built:
		hide()
		return

	if new_level >= required_hub_level:
		show()
	else:
		hide()

func permission_to_build_for_bridge() -> bool:
	if is_bridge_built:
		if is_visible_in_tree():
			hide()
		return false

	if not world_grid:
		world_grid = get_parent() as WorldGrid
		if not world_grid:
			return false

	for building in world_grid.buildings_cache:
		if is_instance_valid(building) and building is Hub:
			if building.Hublevel >= required_hub_level:
				return true

	return false

func complete_bridge_construction() -> void:
	is_bridge_built = true
	hide()
	set_highlight_grid(false)
