@tool
class_name Building
extends Node3D

const BUILDING_PORT_DECAL = preload("uid://uf7gdg37kqtl")

@export var title := "Unnamed Building" # probably not great to duplicate these across both Building and BuildingDefinition, but i can't think of another way to avoid a circular dependency. if you can, please do

@export var dimensions := Vector2i.ONE:
	set(value):
		dimensions = value
		_update_editor_vis()
@export var clearance := 1
@export var grid_size := 10.0 # for the sake of my sanity we will assume this is fixed
@export var bound_vis_padding := 0.01
@export var ports : Array[BuildingPort]
@export var rotation_steps := 0
@export var storage : Dictionary[StringName, ItemStorage]
## needed for material overrides, remember to NOT add MeshBoundsVisualizer to this list
@export var meshes : Array[MeshInstance3D]
@export var definition_paths : String ##For loading definition info when you need it

@export var small_recipes : Dictionary[ItemType, ItemType] # ...?
# i would Politely Advise moving this to small_kitchen.gd, why would the base Building class ever need this?

@export_tool_button("Rebuild ports") var rebuild_ports_button = _rebuild_ports

@export_category("Runtime state (don't edit)")

## world-space origin
@export var origin_cell := Vector2i.ZERO:
	set(value):
		origin_cell = value
		if is_inside_tree():
			update_position()

@export var invalid_cells : Array[Vector2i]
@export var is_active := false
@export var is_ghost := false
@export var definition_CLEAR_ME : BuildingDefinition

@export_tool_button("make definition from current state", "ResourcePreloader") var make_definition_button = _make_definition

@onready var mesh_bounds_visualizer: MeshInstance3D = $MeshBoundsVisualizer


var ports_node: Node3D

func get_local_top_left() -> Vector3:
	return Vector3(-dimensions.x * grid_size, 0, -dimensions.y * grid_size) * 0.5

func top_left_to_pos(cell: Vector2i) -> Vector3:
	var local_top_left = get_local_top_left()
	return local_top_left + Vector3((cell.x + 0.5) * grid_size, 0, (cell.y + 0.5) * grid_size)

func get_cells() -> Array[Vector2i]:
	var cells : Array[Vector2i]
	for x in range(origin_cell.x, origin_cell.x + dimensions.x):
		for y in range(origin_cell.y, origin_cell.y + dimensions.y):
			cells.append(Vector2i(x, y))

	return cells

func get_port(at_cell: Vector2i, from_cell: Vector2i) -> BuildingPort:
	for port in ports:
		var port_world_cell := origin_cell + port.cell_offset
		if port_world_cell == at_cell and (from_cell - at_cell) == port.get_facing_vector():
			return port

	return null

func get_port_storage(port: BuildingPort) -> ItemStorage:
	if storage.has(port.storage_id):
		return storage[port.storage_id]
	else:
		push_warning("(%s) port %s requests storage %s which doesn't exist, creating and returning default" % [name, port, port.storage_id])
		var new_storage = ItemStorage.new()
		storage[port.storage_id] = new_storage
		return new_storage

func set_material_override(material: Material):
	for mesh in meshes:
		mesh.material_override = material

func set_override_property(property_name: StringName, value):
	for mesh in meshes:
		if mesh.material_override:
			mesh.material_override.set_shader_parameter(property_name, value)

func rotate_cell(cell: Vector2i, cell_rotation: int, dims: Vector2i) -> Vector2i:
	match cell_rotation % 4:
		0: return cell
		1: return Vector2i(dims.y - 1 - cell.y, cell.x)
		2: return Vector2i(dims.x - 1 - cell.x, dims.y - 1 - cell.y)
		3: return Vector2i(cell.y, dims.x - 1 - cell.x)
	return cell

func rotate_facing(facing: BuildingPort.Facing, cell_rotation: int) -> BuildingPort.Facing:
	return posmod(facing + cell_rotation, 4) as BuildingPort.Facing

func rotate_dimensions(dims: Vector2i, cell_rotation: int) -> Vector2i:
	if cell_rotation % 2 == 0:
		return dims

	return Vector2i(dims.y, dims.x)

func _ready() -> void:
	var unique_storage : Dictionary[StringName, ItemStorage] = {}
	for key in storage:
		if storage[key] != null:
			unique_storage[key] = storage[key].duplicate(true)
		else:
			unique_storage[key] = ItemStorage.new()
	storage = unique_storage
	_rebuild_ports()
	if !Engine.is_editor_hint():
		mesh_bounds_visualizer.queue_free()
	_extends_ready()

func _extends_ready() -> void:
	pass

# wherever these will eventually be called, they must be called in this order specifically
func tick_produce(_tick: int) -> void:
	pass

func tick_transport() -> void:
	pass

func tick_consume(_tick: int) -> void:
	pass


func _update_editor_vis() -> void:
	if !Engine.is_editor_hint():
		return

	if mesh_bounds_visualizer:
		mesh_bounds_visualizer.scale = Vector3(dimensions.x * grid_size + bound_vis_padding, 1, dimensions.y * grid_size + bound_vis_padding)

func update_position() -> void:
	var grid := get_parent() as WorldGrid
	position = grid.cell_to_world(origin_cell) + Vector3(dimensions.x * grid.cell_size.x * 0.5, 0, dimensions.y * grid.cell_size.y * 0.5)
	rotation.y = -rotation_steps * PI * 0.5
	if ports_node: ports_node.global_rotation.y = 0.0
	reset_physics_interpolation()

func _make_definition():
	if !Engine.is_editor_hint():
		push_error("(%s) _make_definition dangerously called at runtime" % name)
		return

	var def = BuildingDefinition.new()
	def.title = title
	def.dimensions = dimensions
	def.clearance = clearance
	def.ports = ports

	definition_CLEAR_ME = def

func _rebuild_ports():
	if ports_node:
		ports_node.queue_free()
	ports_node = Node3D.new()
	ports_node.name = "Ports"
	add_child(ports_node)

	for port in ports:
		var port_instance : Node3D = BUILDING_PORT_DECAL.instantiate()
		var port_pos = get_local_top_left() + Vector3((port.cell_offset.x + 0.5) * grid_size, 0, (port.cell_offset.y + 0.5) * grid_size)
		port_instance.position = port_pos
		ports_node.add_child(port_instance)
		port.vis_node_path = port_instance.get_path()
		port_instance.set_is_output(port.type == BuildingPort.PortType.EXPORTS)
		var port_direction := port.get_facing_vector()
		port_instance.rotation.y = atan2(port_direction.x, port_direction.y) + PI

func set_show_port(port: BuildingPort, show_: bool) -> void:
	var port_node := get_node(port.vis_node_path) as Node3D
	if port_node:
		port_node.visible = show_

func upgrade() -> bool:
	var upgrade_def := get_upgrade_definition()

	if !upgrade_def:
		push_warning("(%s) attempted to upgrade but cited BuildingDefinition at %s has upgrades_to set to null" % [name, definition_paths])
		return false

	var grid := get_parent() as WorldGrid
	var new_building : Building = upgrade_def.get_building_instance(rotation_steps)
	new_building.origin_cell = origin_cell
	new_building.rotation_steps = rotation_steps

	return grid.replace_building(self, new_building)

func get_upgrade_definition() -> BuildingDefinition:
	var own_def := load(definition_paths) as BuildingDefinition
	return own_def.upgrades_to
