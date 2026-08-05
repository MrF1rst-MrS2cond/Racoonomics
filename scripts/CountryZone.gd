@tool
class_name CountryZone
extends GridRegion

@export var is_country_zone := true
@export var required_hub_level := 1
@export var zone_filter : ItemFilter

@export var population_by_level: Dictionary[int, int] = {
	1: 27,
	2: 27,
	3: 27 * 2,
	4: 27 * 4,
	5: 27 * 4,
	6: 27 * 8
}
@export var default_population: int = 27

var world_grid : WorldGrid

func _ready() -> void:
	super()
	if get_parent() is WorldGrid:
		world_grid = get_parent() as WorldGrid

func get_population_for_level(hub_level: int) -> int:
	if population_by_level.has(hub_level):
		return population_by_level[hub_level]
	return default_population

## Проверка: разблокирована ли зона в зависимости от уровня Hub
func permission_to_build() -> bool:
	if not world_grid:
		world_grid = get_parent() as WorldGrid
		if not world_grid:
			return false

	for building in world_grid.buildings_cache:
		if is_instance_valid(building) and building is Hub:
			if building.Hublevel >= required_hub_level:
				return true

	return false
