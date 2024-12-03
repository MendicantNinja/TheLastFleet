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
var available_group_names: Array[StringName] = [&"group A", &"group B", &"group C", &"group D"]
var taken_group_names: Array[StringName] = []
var tmp_group_name: StringName = &"temporary group"
var tmp_target_name: StringName = &"temporary target"
var highlight_group_name: String = &"highlighted units"
var current_group_name: StringName = &""
var selected_group: Array = []
var target_group: Array = []
var prev_selected_ship: Ship = null
var attack_group: bool = false

# Camera stuff
var zoom_in_limit: Vector2 = Vector2(0.5, 0.5)
var zoom_out_limit: Vector2 = Vector2(0.13, 0.13) 

signal switch_maps()

func _ready():
	SelectionArea.set_collision_mask_value(1, true)
	SelectionArea.set_collision_mask_value(3, true)

func _unhandled_input(event) -> void:
	if not visible:
		return
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("select"):
			box_selection_start = get_global_mouse_position()
		elif Input.is_action_just_released("select") and box_selection_end != Vector2.ZERO:
			select_units()
		elif Input.is_action_just_pressed("m2") and not (Input.is_action_pressed("select") or Input.is_action_pressed("alt select")):
			var to_position: Vector2 = get_global_mouse_position()
			process_move(to_position)
		elif Input.is_action_just_pressed("zoom in") and TacticalCamera.zoom < zoom_in_limit:
			TacticalCamera.zoom += Vector2(0.01, 0.01)
		elif Input.is_action_just_pressed("zoom out") and TacticalCamera.zoom > zoom_out_limit:
			TacticalCamera.zoom -= Vector2(0.01, 0.01)
	elif event is InputEventMouseMotion:
		if Input.is_action_pressed("select") and box_selection_start > Vector2.ZERO:
			box_selection_end = get_global_mouse_position()
			queue_redraw()
		elif Input.is_action_pressed("camera action"):
			TacticalCamera.position -= event.relative / TacticalCamera.zoom
	elif event is InputEventKey:
		if event.keycode == KEY_TAB and event.pressed:
			switch_maps.emit()
		if Input.is_action_pressed("alt select") and selected_group.size() > 0:
			attack_group = true
			selection_line_color = Color(Color.CRIMSON)
			queue_redraw()
		elif Input.is_action_just_released("alt select"):
			if target_group.size() > 0:
				attack_targets()
			attack_group = false
			selection_line_color = settings.gui_color
			queue_redraw()

func process_move(to_position: Vector2) -> void:
	if selected_group.is_empty() and current_group_name.is_empty():
		return
	
	var tmp_group: Array = get_tree().get_nodes_in_group(tmp_group_name)
	if not tmp_group.is_empty() or current_group_name.is_empty():
		move_new_unit(to_position)
		return
	
	var ret_group: Array = get_tree().get_nodes_in_group(current_group_name)
	var in_group: int = 0
	var unit_leaders: Array = []
	for unit in selected_group:
		if unit.group_leader:
			unit_leaders.push_back(unit)
		if unit in ret_group:
			in_group += 1
	
	if selected_group.size() == in_group and unit_leaders.size() == 1:
		move_unit(unit_leaders[0], to_position)
		return
	
	for leader in unit_leaders:
		leader.set_group_leader(false)
	move_new_unit(to_position)

func move_unit(unit_leader: Ship, to_position: Vector2) -> void:
	unit_leader.set_navigation_position(to_position)
	get_viewport().set_input_as_handled()

func move_new_unit(to_position: Vector2) -> void:
	var tmp_group: Array = get_tree().get_nodes_in_group(tmp_group_name)
	if selected_group.is_empty() and tmp_group.is_empty():
		get_viewport().set_input_as_handled()
		return
	
	reset_units_affiliation(tmp_group)
	
	var new_group_name: StringName = available_group_names.pop_back()
	taken_group_names.push_back(new_group_name)
	make_group(tmp_group_name, new_group_name)
	var unit_range: int = tmp_group.size() - 1
	var rand_group_leader: int = randi_range(0, unit_range)
	tmp_group[rand_group_leader].set_group_leader(true)
	current_group_name = new_group_name
	selected_group = tmp_group
	
	move_unit(tmp_group[rand_group_leader], to_position)

# this will require iteration soon
func attack_targets() -> void:
	reset_group_names()
	current_group_name = available_group_names.pop_back()
	taken_group_names.push_back(current_group_name)
	make_group(tmp_group_name, current_group_name)
	
	# These next few lines might cause issues later.
	var target_group_name: StringName = current_group_name + &"targets"
	for unit in target_group:
		unit.add_to_group(highlight_group_name)
		unit.add_to_group(target_group_name)
	get_tree().call_group(target_group_name, "highlight_selection", true)
	
	var group_leader: Ship = null
	var leaders: Array[Ship] = []
	for unit: Ship in get_tree().get_nodes_in_group(current_group_name):
		if unit.group_leader == true:
			leaders.push_back(unit)
			unit.group_leader = false

func select_units() -> void:
	reset_group_names()
	if prev_selected_ship != null:
		_on_ship_selected(prev_selected_ship)
	
	var size: Vector2 = abs(box_selection_end - box_selection_start)
	var area_position: Vector2 = get_rect_start_position()
	SelectionArea.global_position = area_position
	SelectionShape.global_position = area_position + size/2
	SelectionShape.shape.size = size
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	var selection: Array[Node2D] = SelectionArea.get_overlapping_bodies()
	if selection.size() == 0:
		get_tree().call_group(highlight_group_name, "highlight_selection", false)
		get_tree().call_group(highlight_group_name, "remove_group", highlight_group_name)
		get_tree().call_group(tmp_group_name, "remove_group", tmp_group_name)
		target_group.clear()
		selected_group.clear()
		reset_box_selection()
		print("current group name: ", current_group_name)
		return
	
	var tmp_target_group: Array = []
	var tmp_group: Array = []
	for ship in selection:
		if not ship.is_friendly and attack_group:
			tmp_target_group.push_back(ship)
		elif ship.is_friendly and not attack_group and not tmp_group.has(ship):
			tmp_group.push_back(ship)
	
	if attack_group and selected_group.is_empty():
		reset_box_selection()
		return
	elif attack_group and not selected_group.is_empty() and not tmp_target_group.is_empty():
		target_group = tmp_target_group
		attack_targets()
		reset_box_selection()
		return
	
	var prev_group_name: StringName = &""
	var current_names: Array = []
	var same_group_count: int = 0
	
	for unit in tmp_group:
		var in_valid_group: bool = crossreference_unit_groups(unit)
		if in_valid_group and prev_group_name.is_empty():
			current_names.push_back(unit.group_name)
			prev_group_name = unit.group_name
			same_group_count += 1
		elif in_valid_group and unit.group_name == prev_group_name:
			same_group_count += 1
		elif in_valid_group and unit.group_name != prev_group_name and not current_names.has(unit.group_name):
			current_names.push_back(unit.group_name)
		print(unit.name)
		print(prev_group_name)
		print(current_names)
	
	if same_group_count == tmp_group.size():
		selected_group = tmp_group
		make_tmp_group(tmp_group)
		current_group_name = prev_group_name
	elif not tmp_group.is_empty():
		make_tmp_group(tmp_group)
		selected_group = tmp_group
	
	reset_box_selection()

func make_tmp_group(group: Array) -> void:
	get_tree().call_group(highlight_group_name, "highlight_selection", false)
	get_tree().call_group(highlight_group_name, "group_remove", highlight_group_name)
	
	for unit in group:
		unit.highlight_selection(true)
		unit.add_to_group(highlight_group_name)
		unit.add_to_group(tmp_group_name)

func make_group(prev_group_name: StringName, new_group_name: StringName) -> void:
	get_tree().call_group(prev_group_name, "group_add", new_group_name)
	get_tree().call_group(prev_group_name, "group_remove", prev_group_name)
	reset_group_names()

func reset_units_affiliation(group_select: Array) -> void:
	for unit: Ship in group_select:
		if unit.group_leader:
			unit.set_group_leader(false)
		if unit.group_name.is_empty():
			continue
		unit.remove_from_group(unit.group_name)
		unit.group_name = &""
	selected_group.clear()
	reset_group_names()

func crossreference_unit_groups(unit: Ship) -> bool:
	var group_name: StringName = unit.group_name
	if group_name.is_empty() or group_name.begins_with(&"temporary"):
		return false
	return true

func display_map(map_value: bool) -> void:
	# Show the Tac Map
	if map_value == true:
		visible = true
		TacticalCamera.enabled = true
	# Hide the Tac Map
	elif map_value == false:
		TacticalCamera.enabled = false
		target_group = []
		attack_group = false
		visible = false
	
	var friendly_group: Array = get_tree().get_nodes_in_group("friendly")
	var enemy_group: Array = get_tree().get_nodes_in_group("enemy")
	for ship in friendly_group:
		if not ship.alt_select.is_connected(_on_alt_select):
			ship.alt_select.connect(_on_alt_select.bind(ship))
			ship.switch_to_manual.connect(_on_switched_to_manual)
			ship.ship_selected.connect(_on_ship_selected.bind(ship))
	for ship in enemy_group:
		if not ship.alt_select.is_connected(_on_alt_select):
			ship.alt_select.connect(_on_alt_select.bind(ship))
	
	get_tree().call_group("enemy", "display_icon", visible)
	get_tree().call_group("friendly", "display_icon", visible)

func _on_switched_to_manual() -> void:
	if not visible:
		return
	switch_maps.emit()
	reset_box_selection()

func _on_ship_selected(unit: Ship) -> void:
	if prev_selected_ship and prev_selected_ship != unit:
		prev_selected_ship.highlight_selection(false)
	if selected_group.size() >= 1:
		selected_group.clear()
	if prev_selected_ship == unit:
		prev_selected_ship.highlight_selection(false)
		unit.remove_from_group(highlight_group_name)
		unit.remove_from_group(tmp_group_name)
		unit.remove_from_group(unit.group_name)
		unit.group_name = &""
		unit.set_group_leader(false)
		prev_selected_ship = null
		return
	if unit.group_leader == true:
		unit.set_group_leader(false)
		var unit_group: Array = get_tree().get_nodes_in_group(unit.group_name)
		var group_range: int = unit_group.size() - 1
		var rand_select_leader: int = randi_range(0, group_range)
		unit_group[rand_select_leader].set_group_leader(true)
		move_unit(unit_group[rand_select_leader], unit.target_position)
		unit.group_name = &""
	
	unit.add_to_group(tmp_group_name)
	unit.remove_from_group(highlight_group_name)
	get_tree().call_group(highlight_group_name, "highlight_selection", false)
	prev_selected_ship = unit

func _on_alt_select(ship: Ship) -> void:
	if not visible:
		return
	
	reset_box_selection()
	var highlight_value: bool = false
	if selected_group.is_empty() and ship.is_friendly: # initial set up
		selected_group.push_back(ship)
		highlight_value = true
		ship.highlight_selection(highlight_value)
		ship.add_to_group(highlight_group_name)
		ship.add_to_group(tmp_group_name)
		return
	elif target_group.is_empty() and not selected_group.is_empty() and not ship.is_friendly:
		target_group.push_back(ship)
		highlight_value = true
		ship.highlight_selection(highlight_value)
		ship.add_to_group(highlight_group_name)
		ship.add_to_group(tmp_target_name)
		return
	
	if ship.is_friendly and not selected_group.is_empty():
		if not selected_group.has(ship):
			ship.add_to_group(tmp_group_name)
			selected_group.push_back(ship)
			highlight_value = true
		elif selected_group.has(ship):
			ship.remove_from_group(tmp_group_name)
			selected_group.erase(ship)
	
	if not ship.is_friendly and not target_group.is_empty():
		if not target_group.has(ship):
			target_group.push_back(ship)
			highlight_value = true
		elif target_group.has(ship):
			ship.remove_from_group(tmp_target_name)
			target_group.erase(ship)
	
	if target_group.is_empty():
		attack_group = false
	elif not target_group.is_empty():
		attack_group = true
	
	if highlight_value == true:
		ship.add_to_group(highlight_group_name)
	elif highlight_value == false:
		ship.remove_from_group(highlight_group_name)
	
	ship.highlight_selection(highlight_value)

func reset_group_names() -> void:
	for group_name in taken_group_names:
		var group: Array = get_tree().get_nodes_in_group(group_name)
		if group.is_empty():
			available_group_names.push_back(group_name)

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

func reset_box_selection() -> void:
	box_selection_start = Vector2.ZERO
	box_selection_end = Vector2.ZERO
	queue_redraw()

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
	draw_rect(Rect2(start, end - start), selection_line_color, false, 6, true) 
