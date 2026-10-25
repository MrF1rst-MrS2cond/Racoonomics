@tool
class_name PipeSplitter
extends Pipe

var exports : Array[BuildingPort]
var reverse_dests := false

# Кэш связей выходов
var _ids : Array[int] = []
var _storages : Array[ItemStorage] = []

func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid

	import = ports[0]
	exports = ports.slice(1)
	pipe_storage = get_port_storage(import)
	_ids.resize(exports.size())
	_storages.resize(exports.size())

func _subtick_export() -> void:
	var destinations : Array[ItemStorage] = []

	for i in exports.size():
		var dest := _neighbor(exports[i])
		var id := dest.get_instance_id() if dest else 0
		if id != _ids[i]: # новый сосед
			_ids[i] = id
			_storages[i] = _connect(exports[i], dest, BuildingPort.PortType.IMPORTS)

		# Пустой или полный выход пропускаем
		if _storages[i] and !_storages[i].is_full():
			destinations.push_back(_storages[i])

	if destinations.is_empty() or pipe_storage.is_empty():
		return

	reverse_dests = !reverse_dests

	var share := ceili(float(pipe_storage.get_filled_capacity()) / float(destinations.size()))

	for i in range(destinations.size() - 1, -1, -1) if reverse_dests else range(destinations.size()):
		var sent := destinations[i].auto_receive_from(pipe_storage, share)
		print("item movement: splitter sent %s items to dest #%s" % [sent, i])
