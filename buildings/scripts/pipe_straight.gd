@tool
class_name Pipe
extends Building

var world_grid : WorldGrid

var export : BuildingPort
var import : BuildingPort
var pipe_storage : ItemStorage

# Кэш связей, обновляется при смене соседа
var _out_id := 0
var _out_storage : ItemStorage
var _in_id := 0
var _in_storage : ItemStorage
var _in_from_pipe := false

func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid

	export = ports[0]
	import = ports[1]
	pipe_storage = get_port_storage(export)

func tick_transport() -> void:
	if !world_grid:
		return

	_subtick_export()
	_subtick_import()

func _subtick_export() -> void:
	var dest := _neighbor(export)
	var id := dest.get_instance_id() if dest else 0
	if id != _out_id: # новый сосед
		_out_id = id
		_out_storage = _connect(export, dest, BuildingPort.PortType.IMPORTS)

	if !_out_storage or pipe_storage.is_empty():
		return

	var sent := _out_storage.auto_receive_from(pipe_storage)
	if sent > 0: print("item movement: sent %s items to %s" % [sent, dest.name])

func _subtick_import() -> void:
	var source := _neighbor(import)
	var id := source.get_instance_id() if source else 0
	if id != _in_id: # новый сосед
		_in_id = id
		_in_storage = _connect(import, source, BuildingPort.PortType.EXPORTS)
		_in_from_pipe = source is Pipe

	# Трубы толкают сами
	if !_in_storage or _in_from_pipe or _in_storage.is_empty():
		return

	var received := pipe_storage.auto_receive_from(_in_storage)
	if received > 0: print("item movement: received %s items from %s" % [received, source.name])

# Здание за портом
func _neighbor(port: BuildingPort) -> Building:
	var cell := origin_cell + port.cell_offset + port.get_facing_vector()
	return world_grid.get_building_at_cell(cell) as Building

# Проверка порта соседа, иконки портов, склад соседа
func _connect(port: BuildingPort, other: Building, other_type: BuildingPort.PortType) -> ItemStorage:
	var other_port : BuildingPort
	if other:
		var from := origin_cell + port.cell_offset
		other_port = other.get_port(from + port.get_facing_vector(), from)

	var linked := other_port != null and other_port.type == other_type
	set_show_port(port, !linked)
	if !linked:
		return null

	other.set_show_port(other_port, false)
	return other.get_port_storage(other_port)
