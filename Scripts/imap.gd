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
			var normalized_distance: float = distance / radius
			var prop_value: float = max(0, magnitude - magnitude * normalized_distance) # basic linear drop off
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
