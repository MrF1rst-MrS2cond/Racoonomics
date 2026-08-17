@tool
class_name PipeSplitter
extends Pipe

var export_ports: Array[BuildingPort] = []

func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid

	export_ports.clear()
	
	# Автоматически находим вход и все выходы
	for port in ports:
		if port.type == BuildingPort.PortType.IMPORTS:
			import = port
		elif port.type == BuildingPort.PortType.EXPORTS:
			export_ports.append(port)

	if export_ports.size() > 0:
		export = export_ports[0]
		pipe_storage = get_port_storage(export)

func _subtick_export() -> void:
	if pipe_storage.is_empty() or export_ports.is_empty():
		return

	# 1. Находим все валидные подключенные порты приемников
	var active_destinations: Array[Dictionary] = []
	
	for out_port in export_ports:
		var port_from := origin_cell + out_port.cell_offset
		var port_to := port_from + out_port.get_facing_vector()

		var dest_building = world_grid.get_building_at_cell(port_to)
		if !dest_building or !(dest_building is Building):
			set_show_port(out_port, true)
			continue

		var dest_import_port := dest_building.get_port(port_to, port_from) as BuildingPort
		if !dest_import_port or dest_import_port.type != BuildingPort.PortType.IMPORTS:
			set_show_port(out_port, true)
			continue

		set_show_port(out_port, false)
		dest_building.set_show_port(dest_import_port, false)

		var dest_import_storage := dest_building.get_port_storage(dest_import_port) as ItemStorage
		if dest_import_storage and not dest_import_storage.is_full():
			active_destinations.append({
				"storage": dest_import_storage,
				"port": out_port
			})

	if active_destinations.is_empty():
		return

	# 2. Вычисляем равную долю для каждого подключенного выхода
	var total_items := pipe_storage.get_filled_capacity()
	var share_per_port := total_items / active_destinations.size()
	
	# Если предметов меньше, чем портов (например, осталась 1 штука), отдаем хотя бы по 1
	if share_per_port == 0 and total_items > 0:
		share_per_port = 1

	# 3. Равносильно распределяем еду по всем лавкам
	for dest in active_destinations:
		if pipe_storage.is_empty():
			break
			
		var dest_storage: ItemStorage = dest["storage"]
		var filter_to_use = dest_storage.filter if dest_storage.filter else null
		
		# Отдаем ровно рассчитанную долю (например, 18 единиц)
		var amount_to_take := mini(share_per_port, pipe_storage.get_filled_capacity())
		var taken_dict := pipe_storage.take_filtered(filter_to_use, amount_to_take)

		for type_id in taken_dict.keys():
			var type := Global.get_type(type_id)
			if type:
				dest_storage.put(type, taken_dict[type_id])
