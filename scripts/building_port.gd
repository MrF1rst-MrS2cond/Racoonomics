@tool
class_name BuildingPort
extends Resource

enum PortType {
	EXPORTS,
	IMPORTS
}
enum Facing {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

@export var type: PortType = PortType.EXPORTS
## offset relative to building origin
@export var cell_offset: Vector2i = Vector2i.ZERO
@export var facing: Facing
@export var storage_id: StringName
var vis_node_path : NodePath # рантайм, не сохраняется

func get_facing_vector(f := facing) -> Vector2i:
	match f:
		Facing.NORTH: return Vector2i(0, -1)
		Facing.EAST: return Vector2i(1, 0)
		Facing.SOUTH: return Vector2i(0, 1)
		Facing.WEST: return Vector2i(-1, 0)
		_: return Vector2i.ZERO
