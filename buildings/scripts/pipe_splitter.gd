@tool
class_name PipeSplitter
extends Pipe

var exports : Array[BuildingPort]
var reverse_dests := false

func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid

	import = ports[0]
	exports = ports.slice(1)
	pipe_storage = get_port_storage(import)

func _subtick_export() -> void:
	var destinations : Array[ItemStorage]

	for port in exports:
		var port_from := origin_cell + port.cell_offset
		var port_to := port_from + port.get_facing_vector()

		var dest_building = world_grid.get_building_at_cell(port_to)
		if !dest_building or !(dest_building is Building):
			set_show_port(port, true)
			return

		var dest_import_port := dest_building.get_port(port_to, port_from) as BuildingPort
		if !dest_import_port or dest_import_port.type != BuildingPort.PortType.IMPORTS:
			set_show_port(port, true)
			return

		var dest_import_storage := dest_building.get_port_storage(dest_import_port) as ItemStorage
		if !dest_import_storage or dest_import_storage.is_full():
			return

		set_show_port(port, false)
		dest_building.set_show_port(dest_import_port, false)
		destinations.push_back(dest_import_storage)

	if !destinations.size() or pipe_storage.get_filled_capacity() <= 0: return

	reverse_dests = !reverse_dests

	var share := ceili(float(pipe_storage.get_filled_capacity()) / float(destinations.size()))

	for i in range(destinations.size() - 1, -1, -1) if reverse_dests else range(destinations.size()):
		var sent := destinations[i].auto_receive_from(pipe_storage, share)
		print("item movement: splitter sent %s items to dest #%s" % [sent, i])
