extends CountryZone
var world_grid : WorldGrid
@export var is_country_zone := true
@export var required_hub_level := 3
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
	
