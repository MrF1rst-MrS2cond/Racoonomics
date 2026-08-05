@tool
extends FuncBuildings
class_name Store


@export var any_filter : ItemFilter

@onready var animation_player: AnimationPlayer = $Store_lvl2_full/AnimationPlayer

var is_active_func: bool = false
var animation_speed: float = 1.0
var world_grid : WorldGrid
var import : BuildingPort
var is_working: bool = false 

func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid

	if ports.size() > 0:
		import = ports[0]

	if !is_ghost and animation_player:
		animation_player.play(&"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Sleep_idle", -1, animation_speed)


func setup_building(grid_ref: WorldGrid) -> void:
	self.world_grid = grid_ref

	_update_filter_from_zone()

	if storage.has(&"food_input"):
		if storage[&"food_input"].item_added.is_connected(_on_food_input_item_added):
			storage[&"food_input"].item_added.disconnect(_on_food_input_item_added)
		storage[&"food_input"].item_added.connect(_on_food_input_item_added)


func _update_filter_from_zone() -> void:
	if not world_grid:
		return
		
	var zone := world_grid._get_country_zone_at_cell(origin_cell)
	if zone and "zone_filter" in zone and zone.zone_filter != null:
		self.any_filter = zone.zone_filter



func on_click_harvest():
	worktime = 6
	if not is_working:
		_process_food_consumption()


func _on_food_input_item_added(_item_id: StringName) -> void:
	if is_working:
		return
	_process_food_consumption()


func _process_food_consumption() -> void:
	var food_storage := storage[&"food_input"]
	
	while worktime > 0 and food_storage.stacks.size() > 0:
		is_working = true
		var current_item_id : StringName = food_storage.stacks.keys()[0]
		var item_type : ItemType = Global.get_type(current_item_id)
		
		var is_allowed : bool = true
		if any_filter != null and item_type != null:
			is_allowed = any_filter.accepts(item_type)
		if not is_allowed:
			food_storage.stacks[current_item_id] -= 1
			if food_storage.stacks[current_item_id] <= 0:
				food_storage.stacks.erase(current_item_id)

			if animation_player and animation_player.has_animation(&"Rig_Rabbit|Reject"):#анимация недовольства
				animation_player.play(&"Rig_Rabbit|Reject", -1, animation_speed) 
				await animation_player.animation_finished
			continue

		var items_needed := 18
		var current_satiety := 0
		var loyalty_duration : float = item_type.satiety * 9.0 if item_type else 1.0
		
		for item_id in food_storage.stacks.keys():
			if items_needed <= 0:
				break
			
			var current_type : ItemType = Global.get_type(item_id)

			if any_filter != null and current_type != null and not any_filter.accepts(current_type):
				continue

			var available_count : int = food_storage.stacks[item_id]
			var amount_to_take : int = min(available_count, items_needed)
			
			var satiety_value := current_type.satiety if current_type else 1
			current_satiety += amount_to_take # * satiety_value
			items_needed -= amount_to_take
			
			food_storage.stacks[item_id] -= amount_to_take
			if food_storage.stacks[item_id] <= 0:
				food_storage.stacks.erase(item_id)

		if current_satiety > 0:
			if animation_player:
				animation_player.play(&"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Work", -1, animation_speed)
				await animation_player.animation_finished
			
			Global.add_loyalty(current_satiety, loyalty_duration)
			worktime -= 1

	is_working = false

	if animation_player:
		if worktime == 0:
			if animation_player.current_animation != &"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Sleep_idle":
				animation_player.play(&"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Sleep", -1, animation_speed)
				await animation_player.animation_finished
				animation_player.play(&"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Sleep_idle", -1, animation_speed)
		else:
			animation_player.play(&"Rig_Rabbit|Idle", -1, animation_speed)
