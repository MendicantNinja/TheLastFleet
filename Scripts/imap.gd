extends Object
class_name Imap

var anchor_location: Vector2
var cell_size: float # 
var height: int # height of the map
var width: int # width of the map
var map_grid: Array # 2D Array

func _init(new_width: int, new_height: int, x: float = 0.0, y: float = 0.0, new_cell_size: int = 1) -> void:
	width = int(new_width / new_cell_size)
	height = int(new_height / new_cell_size)
	cell_size = new_cell_size
	anchor_location = Vector2(x, y)
	
	map_grid = []
	for i in range(height):
		map_grid.append([])
		for j in range(width):
			map_grid[i].append(0.0)

func get_cell_value(x: int, y: int) -> float:
	if (x >= 0 && x < width && y >= 0 && y < height):
		return map_grid[x][y]
	return 0.0

func set_cell_value(x: int, y: int, value: float) -> void:
	if (x >= 0 && x < width && y >= 0 && y < height):
		map_grid[x][y] = value

func add_value(x: int, y: int, value: float) -> void:
	map_grid[x][y] += value

func propagate_influence(center_x: int, center_y: int, radius: int, magnitude: float = 1.0) -> void:
	var start_x: int = center_x - (radius / 2)
	var start_y: int = center_y - (radius / 2)
	var end_x: int = center_x + (radius / 2)
	var end_y: int = center_y + (radius / 2)
	
	var min_x: int = max(0, start_x)
	var min_y: int = max(0, start_y)
	var max_x: int = min(end_x, width)
	var max_y: int = min(end_y, height)
	
	for y in range(min_y, max_y + 1, 1):
		for x in range(min_x, max_x + 1, 1):
			var p: Vector2 = Vector2(center_x, center_y)
			var q: Vector2 = Vector2(x, y)
			var distance: float = q.distance_to(p)
			var normalized_distance: float = distance / sqrt(radius)
			var prop_value: float = magnitude - magnitude * normalized_distance # basic linear drop off
			map_grid[x][y] = prop_value

func propagate_influence_from_center(magnitude: float = 1.0) -> void:
	var radius: int = height
	var center: Vector2 = Vector2(((radius - 1) / 2), ((radius - 1) / 2))
	for y in range(-radius, radius, 1):
		for x in range(-radius, radius, 1):
			var cell_vector: Vector2 = Vector2(x, y)
			var distance: float = center.distance_to(cell_vector)
			var prop_value: float = max(0, magnitude * exp(-distance / sqrt(center.x)))
			map_grid[x][y] = prop_value

func propagate_influence_as_ring(magnitude: float = 1.0) -> void:
	var radius: int = height
	var center: Vector2 = Vector2(((radius - 1) / 2), ((radius - 1) / 2))
	for y in range(-radius, radius, 1):
		for x in range(-radius, radius, 1):
			var cell_vector: Vector2 = Vector2(x, y)
			var distance: float = center.distance_to(cell_vector)
			var prop_value: float = max(0, magnitude * sin(PI*(distance - (radius - 1)) / center.x))
			map_grid[x][y] = prop_value

func add_map(source_map: Imap, center_x: int, center_y: int, magnitude: float = 1.0, offset_x: int = 0, offset_y: int = 0) -> void:
	if source_map == null:
		assert(source_map != null, "source map required for adding maps together is null")
	
	var start_x: int = center_x + offset_x - (source_map.width / 2)
	var start_y: int = center_y + offset_y - (source_map.height / 2)
	for y in range(0, source_map.height, 1):
		for x in range(0, source_map.width, 1):
			var target_x: int = x + start_x
			var target_y: int = y + start_y
			if (target_x >= 0 && target_x < width && target_y >= 0 && target_y < height):
				map_grid[target_x][target_y] += source_map.get_cell_value(x, y) * magnitude

func add_into_map(target_map: Imap, center_x: int, center_y: int, magnitude: float = 1.0, offset_x: int = 0, offset_y: int = 0) -> void:
	if target_map == null:
		assert(target_map != null, "target map required for adding into current map is null")
	
	# Locate the upper left corner of where we are pushing into the new map
	# Offset is to allow center points that are off this current map --
	# This allows bleed over from adjacet influence maps
	var start_x: int = center_x + offset_x - (target_map.width >> 1)
	var start_y: int = center_y + offset_y - (target_map.height >> 1)
	
	var neg_adj_x: int = 0
	var neg_adj_y: int = 0
	if anchor_location.x < 0.0:
		neg_adj_x = -1
	if anchor_location.y < 0.0:
		neg_adj_y = -1
	
	var min_x: int = max(0, neg_adj_x - start_x)
	var min_y: int = max(0, neg_adj_y - start_y)
	var max_x: int = min(target_map.width, width - start_x + neg_adj_x)
	var max_y: int = min(target_map.height, height - start_y + neg_adj_y)
	for y in range(min_y, max_y, 1):
		for x in range(min_x, max_x, 1):
			var source_x: int = x + start_x - neg_adj_x
			var source_y: int = y + start_y - neg_adj_y
			target_map.add_value(x, y, map_grid[x][y] * magnitude)
