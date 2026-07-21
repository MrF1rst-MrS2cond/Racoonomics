extends CountryZone
var world_grid : WorldGrid
@export var is_country_zone := true
@export var required_hub_level := 3
@export var population_by_level: Dictionary[int, int] = {
	3: 27*2,
	4: 27*2*2,
	5: 27*2*2 
}
@export var default_population: int = 27*2
func get_population_for_level(hub_level: int) -> int:
	if population_by_level.has(hub_level):
		return population_by_level[hub_level]
	return default_population
func _ready() -> void:
	super() 
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid
func permission_to_build():
	if not world_grid:
		return false
	for building in world_grid.buildings_cache:
		if is_instance_valid(building) and building is Hub:
			if building.Hublevel >= required_hub_level:
				return true
			break
	return false
	
