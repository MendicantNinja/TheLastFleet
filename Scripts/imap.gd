extends Object
class_name Imap

var anchor_location: Vector2
var cell_size: float # 
var height: int # height of the map
var width: int # width of the map
var map_grid: Array # 2D Array

func _init(new_width: int, new_height: int, x: float = 0.0, y: float = 0.0, new_cell_size: float = 1.0) -> void:
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

func propagate_influence(centerX: int, centerY: int, radius: int, magnitude: float = 1.0) -> void:
	var startX: int = centerX - (radius / 2)
	var startY: int = centerY - (radius / 2)
	var endX: int = centerX + (radius / 2)
	var endY: int = centerY + (radius / 2)
	
	var minX: int = max(0, startX)
	var minY: int = max(0, startX)
	var maxX: int = min(endX, width)
	var maxY: int = min(endY, height)
	
	for y in range(minY, maxY + 1, 1):
		for x in range(minX, maxX + 1, 1):
			var p: Vector2 = Vector2(centerX, centerY)
			var q: Vector2 = Vector2(x, y)
			var distance: float = q.distance_to(p)
			var normalized_distance: float = distance / radius
			var prop_value: float = 1 - normalized_distance # basic linear drop off
			map_grid[x][y] = prop_value
