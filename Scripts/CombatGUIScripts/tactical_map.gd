extends Node2D

@onready var TacticalCamera = $TacticalCamera
var line_width: int = 30
var line_color: Color = Color8(25, 90, 255, 75)
var grid_drawn: bool = false
var grid_size_y: float = 0.0
var grid_size_x: float = 0.0

# Box Selection
@onready var SelectionArea: Area2D = %SelectionArea
@onready var SelectionShape: CollisionShape2D = %SelectionShape
var box_selection_start: Vector2 = Vector2.ZERO
var box_selection_end: Vector2 = Vector2.ZERO
var selection_line_color: Color = settings.gui_color

# Selection (in general)
var current_group: Array[Ship] = []
var target_group: Array[Ship] = []
var attack_group: bool = false

# Camera limits
var zoom_in_limit: Vector2 = Vector2(0.5, 0.5)
var zoom_out_limit: Vector2 = Vector2(0.13, 0.13) 

signal switch_maps()
signal tmp_unit_select(current_units)
signal attack_targets(current_units, target_units)
signal move_unit(mouse_position)

func _ready():
	SelectionArea.set_collision_mask_value(1, true)
	SelectionArea.set_collision_mask_value(3, true)
	TacticalCamera.enabled = false
	visible = false

func _unhandled_input(event) -> void:
	if not visible:
		return
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("select") and not Input.is_action_pressed("alt select"): 
			box_selection_start = get_global_mouse_position()
		elif Input.is_action_just_released("select") and box_selection_start != Vector2.ZERO and box_selection_end != Vector2.ZERO:
			select_units()
		elif Input.is_action_just_released("alt select") and not current_group.is_empty() and target_group.is_empty():
			tmp_unit_select.emit(current_group)
		elif Input.is_action_just_pressed("m2") and not Input.is_action_pressed("select"):
			move_unit.emit(get_global_mouse_position())
		elif Input.is_action_just_released("alt select") and not current_group.is_empty() and not target_group.is_empty():
			attack_targets.emit(current_group, target_group)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and TacticalCamera.zoom < zoom_in_limit:
			TacticalCamera.zoom += Vector2(0.01, 0.01)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and TacticalCamera.zoom > zoom_out_limit:
			TacticalCamera.zoom -= Vector2(0.01, 0.01)
	elif event is InputEventMouseMotion:
		if Input.is_action_pressed("select") and box_selection_start > Vector2.ZERO:
			box_selection_end = get_global_mouse_position()
			queue_redraw()
			if not Input.is_action_pressed("alt select") and attack_group == true:
				attack_group = false
			elif Input.is_action_pressed("alt select") and attack_group == false:
				attack_group = true

func display_tactical_map() -> void:
	# Show the Tac Map
	if visible == false:
		visible = true
		TacticalCamera.enabled = true
	# Hide the Tac Map
	elif visible == true:
		TacticalCamera.enabled = false
		target_group = []
		attack_group = false
		visible = false
		switch_maps.emit()
	
	var friendly_group: Array = get_tree().get_nodes_in_group("friendly")
	var enemy_group: Array = get_tree().get_nodes_in_group("enemy")
	for ship in friendly_group:
		if ship.alt_select.is_connected(_on_alt_select):
			continue
		ship.alt_select.connect(_on_alt_select.bind(ship))
	for ship in enemy_group:
		if ship.alt_select.is_connected(_on_alt_select):
			continue
		ship.alt_select.connect(_on_alt_select.bind(ship))
	
	get_tree().call_group("enemy", "display_icon", visible)
	get_tree().call_group("friendly", "display_icon", visible)

func _on_alt_select(ship: Ship) -> void:
	if not visible:
		return
	
	if current_group.is_empty() and target_group.is_empty(): # initial set up
		if ship.is_friendly:
			current_group.push_back(ship)
		elif not ship.is_friendly:
			target_group.push_back(ship)
		return
	
	if ship.is_friendly and not current_group.is_empty():
		if not current_group.has(ship):
			current_group.push_back(ship)
		elif current_group.has(ship):
			current_group.erase(ship)
	
	if not ship.is_friendly and not target_group.is_empty():
		if not target_group.has(ship):
			target_group.push_back(ship)
		elif target_group.has(ship):
			target_group.erase(ship)

func select_units() -> void:
	var size: Vector2 = abs(box_selection_end - box_selection_start)
	var area_position: Vector2 = get_rect_start_position()
	SelectionArea.global_position = area_position
	SelectionShape.global_position = area_position + size/2
	SelectionShape.shape.size = size
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	target_group = []
	var selection: Array[Node2D] = SelectionArea.get_overlapping_bodies()
	for ship in selection:
		if not ship.is_friendly and attack_group:
			target_group.push_back(ship)
		elif ship.is_friendly and not attack_group and not current_group.has(ship):
			current_group.push_back(ship)
	
	if target_group and not current_group.is_empty():
		attack_targets.emit(current_group, target_group)
	elif not target_group and not current_group.is_empty():
		tmp_unit_select.emit(current_group)
	
	box_selection_start = Vector2.ZERO
	box_selection_end = Vector2.ZERO
	queue_redraw()

func get_rect_start_position() -> Vector2:
	var new_position: Vector2
	var mouse_position: Vector2 = get_global_mouse_position()
	
	if box_selection_start.x < mouse_position.x:
		new_position.x = box_selection_start.x
	else: new_position.x = mouse_position.x
	
	if box_selection_start.y < mouse_position.y:
		new_position.y = box_selection_start.y
	else: new_position.y = mouse_position.y
	
	return new_position

func set_grid_parameters(size_x: float, size_y: float) -> void:
	grid_size_x = size_x
	grid_size_y = size_y
	queue_redraw()

func _draw():
	if grid_size_x != 0.0 and grid_size_y != 0.0:
		var grid_square_size: int = 2000
		for i in range (grid_size_x/grid_square_size): #Draw Vertical N/S Lines
			draw_line(Vector2(i*grid_square_size, 0), Vector2(i*grid_square_size, grid_size_y), line_color, line_width, true) 
		
		for i in range (grid_size_y/grid_square_size): #Draw Horizontal W/E Lines
			draw_line(Vector2(0, i*grid_square_size), Vector2(grid_size_x, i*grid_square_size), line_color, line_width, true)
	
	if box_selection_start == Vector2.ZERO or visible == false: 
		return
	var end: Vector2 = get_global_mouse_position()
	var start: Vector2 = box_selection_start
	draw_rect(Rect2(start, end - start), settings.gui_color, false, 6, true) 
