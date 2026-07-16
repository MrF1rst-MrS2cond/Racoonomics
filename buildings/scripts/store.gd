@tool
extends FuncBuildings

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

	import = ports[0]

	if !is_ghost:
		animation_player.play(&"Rig_Rabbit|Idle", -1, animation_speed)


func setup_building(grid_ref: WorldGrid) -> void:
	self.world_grid = grid_ref
	if storage.has(&"food_input"):
		if storage[&"food_input"].item_added.is_connected(_on_food_input_item_added):
			storage[&"food_input"].item_added.disconnect(_on_food_input_item_added)
		storage[&"food_input"].item_added.connect(_on_food_input_item_added)

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
		var items_needed := 18
		var current_satiety := 0
		for item_id in food_storage.stacks.keys():
			if items_needed <= 0:
				break
			var item_type : ItemType = Global.get_type(item_id)
			var available_count : int = food_storage.stacks[item_id]
			var amount_to_take : int = min(available_count, items_needed)
			current_satiety += item_type.satiety * amount_to_take
			items_needed -= amount_to_take
			food_storage.stacks[item_id] -= amount_to_take
			if food_storage.stacks[item_id] <= 0:
				food_storage.stacks.erase(item_id)
		#for item_id in food_storage.stacks:
			#var item_type : ItemType = Global.get_type(item_id)
			#var item_count : int = food_storage.stacks[item_id]
			#current_satiety += item_type.satiety * item_count
		#food_storage.stacks.clear()
		
		if current_satiety > 0:
			animation_player.play(&"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Work", -1, animation_speed)
			await animation_player.animation_finished
			Global.add_loyalty(current_satiety)
			worktime -= 1
	is_working = false
	if worktime == 0:
		if animation_player.current_animation != &"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Sleep_idle":
			animation_player.play(&"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Sleep", -1, animation_speed)
			await animation_player.animation_finished
			animation_player.play(&"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Sleep_idle",-1,animation_speed)
	else:
		animation_player.play(&"Rig_Rabbit|Idle", -1, animation_speed)
	
#@tool
#extends FuncBuildings
#@export var any_filter : ItemFilter
#
#@onready var animation_player: AnimationPlayer = $Store_lvl2_full/AnimationPlayer
#var stored_satiety: int = 0
#var animation_speed: float = 1.0
#var is_active_func: bool = false
#var world_grid : WorldGrid
#
#var import : BuildingPort
#
#func _extends_ready() -> void:
	#var parent_grid := get_parent() as WorldGrid
	#if parent_grid:
		#world_grid = parent_grid
#
	#import = ports[0]
#
	#if !is_ghost:
		#pass
		##animation_player.play(&"Rig_Rabbit|Work", -1, animation_speed)
	#animation_player.play(&"Rig_Rabbit|Idle",-1,animation_speed)
#
#func setup_building(grid_ref: WorldGrid) -> void:
	#self.world_grid = grid_ref
	#if storage.has(&"food_input"):
		#if storage[&"food_input"].item_added.is_connected(_on_food_input_item_added):
			#storage[&"food_input"].item_added.disconnect(_on_food_input_item_added)
		#storage[&"food_input"].item_added.connect(_on_food_input_item_added)
		#
#
#
#func _on_food_input_item_added(_item_id: StringName) -> void:
	#var food_storage := storage[&"food_input"]
#
	#for item_id in food_storage.stacks:
		#var item_type : ItemType = Global.get_type(item_id)
		#var item_count : int = food_storage.stacks[item_id]
		#stored_satiety += item_type.satiety * item_count
	#food_storage.stacks.clear()
#
#
#func on_click_harvest():
	#is_active_func = true
#
#func tick_consume(tick: int) -> void:
	## Если магазин не активен (не кликали), ничего не делаем
	#if not is_active:
		#return 
	#if stored_satiety > 0:
		#if animation_player.current_animation != &"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Work":
			#animation_player.play(&"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Work", -1, animation_speed)
		#await animation_player.animation_finished
		#Global.add_loyalty(stored_satiety)
		#stored_satiety = 0
	#else:
		## Если еда закончилась, переходим в Idle
		#if animation_player.current_animation != &"Rig_Rabbit|Idle":
			#animation_player.play(&"Rig_Rabbit|Idle", -1, animation_speed)
#
##func tick_consume(tick: int) -> void:
	##if not is_active_func:
		##return
	##var total_satiety := 0
	##for item_id in storage[&"food_input"].stacks:
		##var item_type : ItemType = Global.get_type(item_id)
		##var item_count : int = storage[&"food_input"].stacks[item_id]
		##total_satiety += item_type.satiety * item_count
		##animation_player.play(&"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Work", -1, animation_speed)
	##storage[&"food_input"].stacks.clear()
	##Global.add_loyalty(total_satiety)
	##is_active_func = false
	##if not animation_player.current_animation != &"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Work":
		##await animation_player.animation_finished
		##animation_player.play(&"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Sleep", -1, animation_speed)
		##await animation_player.animation_finished
		##animation_player.play(&"Rig_Rabbit|Rig_Rabbit|Rig_Rabbit|Sleep_idle", -1, animation_speed)
	##
