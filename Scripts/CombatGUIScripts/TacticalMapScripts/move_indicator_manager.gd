extends Node2D

var MoveIndicator
var move_indicators: Dictionary = {}

var global_map_size: Vector2
var tactical_map_size: Vector2

signal add_indicator(indicator)

func _ready() -> void:
	MoveIndicator = preload("res://Scenes/GUIScenes/OtherGUIScenes/MoveIndicator.tscn").instantiate()

func add_indicator_for_unit(unit: Ship):
	if move_indicators.has(unit.get_instance_id()):
		return  # already exists
	
	var indicator = MoveIndicator.duplicate()
	add_indicator.emit(indicator)  # or to the proper container node
	#indicator.setup()  # perform your indicator-specific setup here
	move_indicators[unit.get_instance_id()] = indicator

func _on_remove_indicator_for_unit(unit: Ship):
	var id = unit.get_instance_id()
	if move_indicators.has(id):
		move_indicators[id].queue_free()
		move_indicators.erase(id)

func _on_move_order_updated(target_position: Vector2, unit: Ship) -> void:
	var id = unit.get_instance_id()
	if move_indicators.has(id) and target_position == Vector2.ZERO:
		_on_remove_indicator_for_unit(unit)
	elif move_indicators.has(id) and target_position != Vector2.ZERO:
		update_position(move_indicators[id], target_position)
	else:
		add_indicator_for_unit(unit)
		update_position(move_indicators[id], target_position)

func update_position(indicator, target_position: Vector2) -> void:
	# truncate position to get cell idx
	var cell_idx: Vector2i = Vector2i(target_position.y / imap_manager.DefaultCellSize, target_position.x / imap_manager.DefaultCellSize)
	# convert back to get the top left corner of the cell
	var cell_position: Vector2 = Vector2(cell_idx.y * imap_manager.DefaultCellSize, cell_idx.y * imap_manager.DefaultCellSize)
	# reset position of the move indicator to the top left corner, where the indicators size should match the cell size
	var new_position: Vector2 = Vector2(
		target_position.x * (tactical_map_size.x / global_map_size.x),
		target_position.y * (tactical_map_size.y / global_map_size.y)
	)
	indicator.position = new_position
