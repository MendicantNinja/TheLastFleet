extends Object
class_name ImapTemplate

var max_radius: int
var type: int
var template_maps: Dictionary = {}

func init_occupancy_map_templates(n_radius: int, magnitude: float = 1.0) -> void:
	max_radius = n_radius
	var new_template_maps: Dictionary = {}
	for r in range(1, max_radius + 1, 1):
		var size: int = (2 * r) + 1
		var new_map: Imap = Imap.new(size, size)
		new_map.propagate_influence_from_center(magnitude)
		new_template_maps[r] = new_map
	template_maps = new_template_maps

func init_threat_map_templates(n_radius: int, magnitude: float = 1.0) -> void:
	max_radius = n_radius
	var new_template_maps: Dictionary = {}
	for r in range(1, max_radius + 1, 1):
		var size: int = (2 * r) + 1
		var new_map: Imap = Imap.new(size, size)
		new_map.propagate_influence_as_ring(magnitude)
		new_template_maps[r] = new_map
	template_maps = new_template_maps
