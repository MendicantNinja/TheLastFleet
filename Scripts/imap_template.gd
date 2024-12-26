extends Object
class_name ImapTemplate

enum TemplateType {
	OCCUPANCY_TEMPLATE, # Occupancy indicates the space a unit occupies and its zone of influence.
	THREAT_TEMPLATE, # Threat denotes its attack abilities such as the strength of its weapons and accuracy.
}

var max_radius: int
var type: TemplateType
var map_grid: Dictionary = {}

func init_occupancy_map_templates(n_radius: int, magnitude: float = 1.0) -> void:
	max_radius = n_radius
	type = TemplateType.OCCUPANCY_TEMPLATE
	var new_map_grid: Dictionary = {}
	for r in range(1, max_radius + 1, 1):
		var size: int = (2 * r) + 1
		var new_map: Imap = Imap.new(size, size)
		new_map.propagate_influence_from_center(magnitude)
		new_map_grid[r] = new_map
	map_grid = new_map_grid

func init_threat_map_templates(n_radius: int, magnitude: float = 1.0) -> void:
	max_radius = n_radius
	type = TemplateType.THREAT_TEMPLATE
	var new_map_grid: Dictionary = {}
	for r in range(1, max_radius + 1, 1):
		var size: int = (2 * r) + 1
		var new_map: Imap = Imap.new(size, size)
		new_map.propagate_influence_as_ring(magnitude)
		new_map_grid[r] = new_map
	map_grid = new_map_grid
