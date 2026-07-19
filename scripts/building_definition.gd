class_name BuildingDefinition
extends Resource

@export var title := "Unnamed Building"
@export_multiline var description := "If you're seeing this, there's probably a bug"
@export var shop_icon : Texture2D
@export var required_hub_level: int = 1
@export var dimensions := Vector2i.ONE
@export var clearance := 1
@export var ports : Array[BuildingPort]
@export var building_scene : PackedScene
@export var upgrades_to : BuildingDefinition
@export var level := 1

@export var purchase_cost: int = 0
@export var upgrade_cost: int = 0
@export var is_for_small_region: bool = false

func get_building_instance(rotation: int = 0) -> Building:
	var building = building_scene.instantiate() as Building
	building.title = title
	building.dimensions = rotate_dimensions(dimensions, rotation)
	building.clearance = clearance
	building.rotation_steps = rotation

	var rotated_ports: Array[BuildingPort] = []
	for port in ports:
		var p = port.duplicate() as BuildingPort
		p.cell_offset = rotate_cell(port.cell_offset, rotation, dimensions)
		p.facing = rotate_facing(port.facing, rotation) as BuildingPort.Facing
		rotated_ports.append(p)

	building.ports = rotated_ports
	return building

func rotate_facing(facing: BuildingPort.Facing, cell_rotation: int) -> BuildingPort.Facing:
	return posmod(facing + cell_rotation, 4) as BuildingPort.Facing

func rotate_cell(cell: Vector2i, cell_rotation: int, dims: Vector2i) -> Vector2i:
	match cell_rotation % 4:
		0: return cell
		1: return Vector2i(dims.y - 1 - cell.y, cell.x)
		2: return Vector2i(dims.x - 1 - cell.x, dims.y - 1 - cell.y)
		3: return Vector2i(cell.y, dims.x - 1 - cell.x)
	return cell

func rotate_dimensions(dims: Vector2i, cell_rotation: int) -> Vector2i:
	if cell_rotation % 2 == 0:
		return dims

	return Vector2i(dims.y, dims.x)
