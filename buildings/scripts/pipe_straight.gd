@tool
class_name Pipe
extends Building

var world_grid : WorldGrid

var export : BuildingPort
var import : BuildingPort
var pipe_storage : ItemStorage

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
	# if pipe_storage.is_empty():
	# 	return

	var port_from := origin_cell + export.cell_offset
	var port_to := port_from + export.get_facing_vector()

	var dest_building = world_grid.get_building_at_cell(port_to)
	if !dest_building or !(dest_building is Building):
		set_show_port(export, true)
		return

	var dest_import_port := dest_building.get_port(port_to, port_from) as BuildingPort
	if !dest_import_port or dest_import_port.type != BuildingPort.PortType.IMPORTS:
		set_show_port(export, true)
		return

	set_show_port(export, false)
	dest_building.set_show_port(dest_import_port, false)
	var dest_import_storage := dest_building.get_port_storage(dest_import_port) as ItemStorage
	if !dest_import_storage or dest_import_storage.is_full():
		return

	var sent := dest_import_storage.auto_receive_from(pipe_storage)
	if sent > 0: print("item movement: sent %s items to %s" % [sent, dest_building.name])

func _subtick_import() -> void:
	var port_from := origin_cell + import.cell_offset
	var port_to := port_from + import.get_facing_vector()

	var source_building = world_grid.get_building_at_cell(port_to)
	if !source_building or !(source_building is Building):
		set_show_port(import, true)
		return

	var source_export_port := source_building.get_port(port_to, port_from) as BuildingPort
	if !source_export_port or source_export_port.type != BuildingPort.PortType.EXPORTS:
		set_show_port(import, true)
		return

	set_show_port(import, false)
	source_building.set_show_port(source_export_port, false)
	var source_export_storage := source_building.get_port_storage(source_export_port) as ItemStorage
	if !source_export_storage or source_export_storage.is_empty():
		return

	var received := pipe_storage.auto_receive_from(source_export_storage)
	if received > 0: print("item movement: received %s items from %s" % [received, source_building.name])
