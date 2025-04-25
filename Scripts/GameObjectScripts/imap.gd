extends Object
class_name Imap

var anchor_location: Vector2
var cell_size: int 
var height: int # height of the map
var width: int # width of the map
var map_grid: Array # 2D Array
var map_type: int

signal update_grid_value(m, n, value)
signal update_row_value(m, values)

@warning_ignore("integer_division")
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

func get_cell_value(n: int, m: int) -> float:
	if (n >= 0 && n < width && m >= 0 && m < height):
		return map_grid[n][m]
	return 0.0

func set_cell_value(n: int, m: int, value: float) -> void:
	if (n >= 0 && n < width && m >= 0 && m < height):
		map_grid[n][m] = value
		update_grid_value.emit(n, m, value)

func add_value(n: int, m: int, value: float) -> void:
	map_grid[n][m] += value
	update_grid_value.emit(n, m, map_grid[n][m])

func clear_map() -> void:
	for m in range(0, height):
		var row_reset: Array = []
		row_reset.resize(width)
		row_reset.fill(0.0)
		map_grid[m] = row_reset
		#update_row_value.emit(m, row_reset) 
		# Might need that for debugging but unlikely

@warning_ignore("integer_division", "narrowing_conversion")
func find_cell_index_from_position(position: Vector2) -> Vector2:
	var indices: Vector2i = Vector2i.ZERO
	var cell_column: int = position.x / cell_size
	var cell_row: int = position.y / cell_size
	indices = Vector2i(cell_column, cell_row)
	return indices

@warning_ignore("integer_division")
func propagate_influence_from_center(magnitude: float = 1.0) -> void:
	var radius: int = height
	var center: Vector2 = Vector2(((radius - 1) / 2), ((radius - 1) / 2))
	for m in range(-radius, radius, 1):
		for n in range(-radius, radius, 1):
			var cell_vector: Vector2 = Vector2(n, m)
			var distance: float = center.distance_to(cell_vector)
			var prop_value: float = magnitude - magnitude * (distance / radius)
			set_cell_value(n, m, prop_value)

@warning_ignore("integer_division")
func propagate_influence_as_ring(magnitude: float = 1.0, sigma: float = 1.0) -> void:
	var radius: int = height
	var center: Vector2 = Vector2(((radius - 1) / 2), ((radius - 1) / 2))
	for m in range(-radius, radius, 1):
		for n in range(-radius, radius, 1):
			var cell_vector: Vector2 = Vector2(n, m)
			var distance: float = center.distance_to(cell_vector)
			var prop_value: float = (magnitude / ( sigma * sqrt(2 * PI))) * exp(-(distance - center.x / 2)**2 / (2 * sigma**2))
			#var prop_value: float = magnitude * sin(PI*(distance - (radius - 1)) / center.x)
			
			set_cell_value(n, m, prop_value)

@warning_ignore("integer_division")
func add_map(source_map: Imap, center_row: int, center_column: int, magnitude: float = 1.0, offset_column: int = 0, offset_row: int = 0) -> void:
	if source_map == null:
		assert(source_map != null, "source map required for adding maps together is null")
	
	var start_column: int = center_column + offset_column - source_map.width / 2
	var start_row: int = center_row + offset_row - source_map.height / 2
	for m in range(0, source_map.height, 1):
		for n in range(0, source_map.width, 1):
			var target_row: int = m + start_row
			var target_col: int = n + start_column
			var value: float = 0.0
			if (target_col >= 0 && target_col < width && target_row >= 0 && target_row < height):
				value = map_grid[target_row][target_col] + source_map.map_grid[m][n] * magnitude
				if snappedf(value, 0.1) == 0.0:
					value = 0.0
				map_grid[target_row][target_col] = value
				update_grid_value.emit(target_row, target_col, map_grid[target_row][target_col])

@warning_ignore("integer_division")
func subtract_map(source_map: Imap, center_row: int, center_column: int, magnitude: float = 1.0, offset_column: int = 0, offset_row: int = 0) -> void:
	if source_map == null:
		assert(source_map != null, "source map required for adding maps together is null")
	
	var start_column: int = center_column + offset_column - source_map.width / 2
	var start_row: int = center_row + offset_row - source_map.height / 2
	for m in range(0, source_map.height, 1):
		for n in range(0, source_map.width, 1):
			var target_row: int = m + start_row
			var target_col: int = n + start_column
			var value: float = 0.0
			if (target_col >= 0 && target_col < width && target_row >= 0 && target_row < height):
				value = map_grid[target_row][target_col] + source_map.map_grid[m][n] * magnitude
				if snappedf(value, 0.1) == 0.0:
					value = 0.0
				map_grid[target_row][target_col] = value
				update_grid_value.emit(target_row, target_col, map_grid[target_row][target_col])

@warning_ignore("integer_division")
func add_into_map(target_map: Imap, center_column: int, center_row: int, magnitude: float = 1.0, offset_column: int = 0, offset_row: int = 0) -> void:
	if target_map == null:
		assert(target_map != null, "target map required for adding into current map is null")
	
	# Locate the upper left corner of where we are pushing into the new map
	# Offset is to allow center points that are off this current map --
	# This allows bleed over from adjacent influence maps
	# The right shift operator essentially divides the length by a power of two
	var start_column: int = center_column + offset_column - (target_map.width >> 1)
	var start_row: int = center_row + offset_row - (target_map.height >> 1)
	
	var neg_adj_col: int = 0
	var neg_adj_row: int = 0
	if anchor_location.x < 0.0:
		neg_adj_col = -1
	if anchor_location.y < 0.0:
		neg_adj_row = -1
	
	var min_n: int = max(0, neg_adj_col - start_column)
	var min_m: int = max(0, neg_adj_row - start_row)
	var max_n: int = min(target_map.width, width - start_column + neg_adj_col)
	var max_m: int = min(target_map.height, height - start_row + neg_adj_row)
	for m in range(min_m, max_m, 1):
		var source_row: int = m + start_row - neg_adj_row
		var source_min: float = map_grid[source_row].min()
		var source_max: float = map_grid[source_row].max()
		if source_min == 0 and source_max == 0:
			var fill_zero: Array = []
			fill_zero.resize(target_map.map_grid[0].size())
			fill_zero.fill(0.0)
			target_map.map_grid[m] = fill_zero
			continue
		
		for n in range(min_n, max_n, 1):
			var source_col: int = n + start_column - neg_adj_col
			target_map.map_grid[m][n] = map_grid[source_row][source_col] * magnitude
