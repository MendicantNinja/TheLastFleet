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
var current_groups: Dictionary = {}
var tmp_group_name: StringName = &"temporary group"
var tmp_target_name: StringName = &"temporary target"
var highlight_group_name: StringName = &"friendly selection"
var highlight_enemy_name: StringName = &"enemy selection"
var current_group_name: StringName = &""
var current_selected_group: Array = []
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
		var highlighted_group: Array = get_tree().get_nodes_in_group(highlight_group_name)
		var highlighted_enemy_group: Array = get_tree().get_nodes_in_group(highlight_enemy_name)
		if event.keycode == KEY_TAB and event.pressed:
			switch_maps.emit()
		if Input.is_action_pressed("alt select") and highlighted_group.size() > 0:
			attack_group = true
			selection_line_color = Color(Color.CRIMSON)
			queue_redraw()
		elif Input.is_action_just_released("alt select"):
			if highlighted_enemy_group.size() > 0:
				attack_targets()
			attack_group = false
			selection_line_color = settings.gui_color
			queue_redraw()

func process_move(to_position: Vector2) -> void:
	var highlighted_group: Array = get_tree().get_nodes_in_group(highlight_group_name)
	var prev_group: Array = get_tree().get_nodes_in_group(current_group_name)
	
	var unit_leaders: Array = []
	for unit in highlighted_group:
		if unit.group_leader:
			unit_leaders.push_back(unit)
	
	var funny_pair: Array = current_groups.values()
	for pair in funny_pair:
		if highlighted_group == pair and unit_leaders.size() == 1:
			var leader = unit_leaders[0]
			move_unit(unit_leaders[0], to_position)
			return
	
	if prev_group.size() == highlighted_group.size() and unit_leaders.size() == 1:
		var leader = unit_leaders[0]
		if leader in prev_group and leader in highlighted_group:
			move_unit(unit_leaders[0], to_position)
			return
	
	for leader: Ship in unit_leaders:
		leader.set_group_leader(false)
	
	reset_group_affiliation(highlighted_group)
	move_new_unit(to_position)

func move_unit(unit_leader: Ship, to_position: Vector2) -> void:
	unit_leader.set_navigation_position(to_position)
	get_viewport().set_input_as_handled()

func move_new_unit(to_position: Vector2) -> void:
	var highlighted_group: Array = get_tree().get_nodes_in_group(highlight_group_name)
	if highlighted_group.is_empty():
		get_viewport().set_input_as_handled()
		return
	
	var new_group_name: StringName = available_group_names.pop_back()
	taken_group_names.push_back(new_group_name)
	get_tree().call_group(highlight_group_name, "group_add", new_group_name)
	
	var unit_range: int = highlighted_group.size() - 1
	var pick_leader: int = randi_range(0, unit_range)
	var new_leader: Ship = highlighted_group[pick_leader]
	new_leader.set_group_leader(true)
	current_group_name = new_group_name
	current_selected_group = highlighted_group
	current_groups[current_group_name] = current_selected_group
	current_groups[current_group_name].sort()
	
	move_unit(new_leader, to_position)

# this will require iteration soon
func attack_targets() -> void:
	var highlighted_group: Array = get_tree().get_nodes_in_group(highlight_group_name)
	reset_group_affiliation(highlighted_group)
	var group_leaders: Array = []
	for unit in highlighted_group:
		if unit.group_leader:
			group_leaders.push_back(unit)
	
	var group_lead: Ship = null
	if group_leaders.size() == 0:
		var unit_range: int = highlighted_group.size() - 1
		var pick_leader: int = randi_range(0, unit_range)
		var new_leader: Ship = highlighted_group[pick_leader]
		group_lead.set_group_leader(true)
		#current_group_name = new_group_name
		#current_selected_group = highlighted_group
	elif group_leaders.size() == 1:
		group_lead = group_leaders[0]
	elif group_leaders.size() > 1:
		for leader: Ship in group_leaders:
			leader.set_group_leader(false)
	
	get_tree().call_group(highlight_enemy_name, "highlight_selection", true)
	
	pass

func select_units() -> void:
	var size: Vector2 = abs(box_selection_end - box_selection_start)
	var area_position: Vector2 = get_rect_start_position()
	SelectionArea.global_position = area_position
	SelectionShape.global_position = area_position + size/2
	SelectionShape.shape.size = size
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	var selection: Array[Node2D] = SelectionArea.get_overlapping_bodies()
	reset_box_selection()
	
	if attack_group == true and selection.size() == 0:
		get_tree().call_group(highlight_enemy_name, "highlight_selection", false)
		get_tree().call_group(highlight_enemy_name, "group_remove", highlight_enemy_name)
		return
	elif attack_group == false and selection.size() == 0:
		get_tree().call_group(highlight_group_name, "highlight_selection", false)
		get_tree().call_group(highlight_group_name, "group_remove", highlight_group_name)
		current_group_name = &""
		return
	
	var past_group: Array = get_tree().get_nodes_in_group(highlight_group_name)
	for ship in past_group:
		if not ship in selection:
			ship.highlight_selection(false)
			ship.remove_from_group(highlight_group_name)
			ship.remove_from_group(highlight_enemy_name)
	
	for ship in selection:
		if not ship.is_friendly and attack_group == true:
			ship.add_to_group(highlight_enemy_name)
		elif ship.is_friendly and attack_group == false:
			ship.add_to_group(highlight_group_name)
	
	if attack_group:
		attack_targets()
		return
	
	current_selected_group.clear()
	get_tree().call_group(highlight_group_name, "highlight_selection", true)

func reset_group_affiliation(group_select: Array) -> void:
	for unit: Ship in group_select:
		if unit.group_leader:
			unit.set_group_leader(false)
		unit.remove_from_group(unit.group_name)
		unit.group_name = &""
	
	var count_down: int = taken_group_names.size() - 1
	for group_idx in range(count_down, -1, -1):
		var group_name: StringName = taken_group_names[group_idx]
		var group: Array = get_tree().get_nodes_in_group(group_name)
		if group.is_empty():
			taken_group_names.remove_at(group_idx)
			available_group_names.push_back(group_name)

func reset_current_group_leader(unit: Ship) -> void:
	unit.remove_from_group(unit.group_name)
	var group: Array = get_tree().get_nodes_in_group(unit.group_name)
	var group_range: int = group.size() - 1
	var rand_select_leader: int = randi_range(0, group_range)
	var new_leader: Ship = group[rand_select_leader]
	if not unit.ShipNavigationAgent.is_navigation_finished():
		var distance_to_position: float = unit.position.distance_to(unit.target_position)
		var angle_to_position: float = unit.position.angle_to(unit.target_position)
		var rotate_direction: Vector2 = new_leader.transform.x.rotated(angle_to_position)
		var delta_position: Vector2 = rotate_direction * distance_to_position
		var relative_position: Vector2 = new_leader.position + delta_position
		new_leader.set_group_leader(true)
		new_leader.set_navigation_position(relative_position)
	unit.set_group_leader(false)

func reset_box_selection() -> void:
	box_selection_start = Vector2.ZERO
	box_selection_end = Vector2.ZERO
	queue_redraw()

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

func _on_alt_select(ship: Ship) -> void:
	if not visible:
		return
	
	var highlighted_group: Array = get_tree().get_nodes_in_group(highlight_group_name)
	var highlighted_enemies: Array = get_tree().get_nodes_in_group(highlight_enemy_name)
	
	reset_box_selection()
	var highlight_value: bool = false
	if highlighted_group.is_empty() and ship.is_friendly: # initial set up
		highlight_value = true
		ship.highlight_selection(highlight_value)
		ship.add_to_group(highlight_group_name)
		return
	elif highlighted_enemies.is_empty() and not ship.is_friendly:
		highlight_value = true
		ship.highlight_selection(highlight_value)
		ship.add_to_group(highlight_enemy_name)
		return
	
	if ship.is_friendly and not highlighted_group.is_empty():
		if not highlighted_group.has(ship):
			ship.add_to_group(highlight_group_name)
			highlight_value = true
		elif highlighted_group.has(ship):
			ship.remove_from_group(highlight_group_name)
	
	if not ship.is_friendly and not highlighted_group.is_empty():
		if not highlighted_enemies.has(ship):
			ship.add_to_group(highlight_enemy_name)
			highlight_value = true
		elif highlighted_enemies.has(ship):
			ship.remove_from_group(highlight_enemy_name)
	
	if highlighted_enemies.is_empty():
		attack_group = false
	elif not highlighted_enemies.is_empty():
		attack_group = true
	
	ship.highlight_selection(highlight_value)

func _on_ship_selected(unit: Ship) -> void:
	var current_selection: Array = get_tree().get_nodes_in_group(current_group_name)
	if current_selection.size() > 1 and unit != prev_selected_ship:
		if unit.group_leader == true:
			reset_current_group_leader(unit)
	
	get_tree().call_group(highlight_group_name, "highlight_selection", false)
	get_tree().call_group(highlight_group_name, "group_remove", highlight_group_name)
	
	if prev_selected_ship == unit:
		unit.highlight_selection(false)
		prev_selected_ship = null
		return
	
	unit.add_to_group(highlight_group_name)
	unit.highlight_selection(true)
	prev_selected_ship = unit

func _on_switched_to_manual() -> void:
	if not visible:
		return
	switch_maps.emit()
	reset_box_selection()

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
	draw_rect(Rect2(start, end - start), selection_line_color, false, 6, true) 
