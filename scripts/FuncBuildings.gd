@tool
class_name FuncBuildings
extends WorkBuilding
## База лавок и кухонь: берут предметы из входного склада

var manual := true # true - работает по клику, false - сама
var portion := 18 # сколько предметов за раз


func setup_building(grid_ref: WorldGrid) -> void:
	world_grid = grid_ref
	_on_setup()
	var input: ItemStorage = storage.get(_input_key())
	if input and not input.item_added.is_connected(_on_item_added):
		input.item_added.connect(_on_item_added)


func on_click_harvest() -> void:
	if not manual:
		return
	worktime = 12
	if not running:
		_work()


func _on_item_added(_id: StringName) -> void:
	if not running:
		_work()


func _input_key() -> StringName: # хук: имя входного склада
	return &""


func _on_setup() -> void: # хук
	pass


func _work() -> void: # хук: основной цикл
	pass
