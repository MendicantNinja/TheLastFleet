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

# Group Creation
var group_iterator: int = 0
var available_group_names: Array[StringName] = []
var taken_group_names: Array[StringName] = []
var current_groups: Dictionary = {}
var highlight_group_name: StringName = &"friendly selection"
var highlight_enemy_name: StringName = &"enemy selection"
var current_group_name: StringName = &""
var prev_selected_ship: Ship = null
var attack_group: bool = false

# Camera stuff
var zoom_in_limit: Vector2 = Vector2(0.9, 0.9)
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
		elif Input.is_action_just_pressed("camera_zoom_in") and TacticalCamera.zoom < zoom_in_limit:
			TacticalCamera.zoom += Vector2(0.01, 0.01)
		elif Input.is_action_just_pressed("camera_zoom_out") and TacticalCamera.zoom > zoom_out_limit:
			TacticalCamera.zoom -= Vector2(0.01, 0.01)
	elif event is InputEventMouseMotion:
		if Input.is_action_pressed("select") and box_selection_start > Vector2.ZERO:
			box_selection_end = get_global_mouse_position()
			queue_redraw()
		elif Input.is_action_pressed("camera_pan"):
			TacticalCamera.position -= event.relative / TacticalCamera.zoom
	elif event is InputEventKey:
		var highlighted_group: Array = get_tree().get_nodes_in_group(highlight_group_name)
		var highlighted_enemy_group: Array = get_tree().get_nodes_in_group(highlight_enemy_name)
		if event.keycode == KEY_TAB and event.pressed:
			switch_maps.emit()
		if Input.is_action_pressed("alt select") and  Input.is_action_pressed("select") and highlighted_group.size() > 0:
			attack_group = true
			selection_line_color = Color(Color.CRIMSON)
			queue_redraw()
		elif Input.is_action_just_released("alt select"):
			if highlighted_group.size() > 0 and highlighted_enemy_group.size() > 0:
				attack_targets()
			attack_group = false
			selection_line_color = settings.gui_color
			queue_redraw()

func process_move(to_position: Vector2) -> void:
	# input, process_move, IF already existing move_unit, 
	# else if not already existing: move_new_unit, reset_group_affiliation, move_unit
	var highlighted_group: Array = get_tree().get_nodes_in_group(highlight_group_name)
	if highlighted_group.size() == 0:
		return
	
	var group_leaders: Array = []
	for unit in highlighted_group:
		if unit.group_leader:
			group_leaders.push_back(unit)
	
	# If the group we're selecting is already a group that exists, move it and do not proceed.
	var group_array: Array = current_groups.values()
	for group in group_array:
		if highlighted_group == group and group_leaders.size() == 1:
			move_unit(group_leaders[0], to_position)
			return
	
	#var prev_group: Array = get_tree().get_nodes_in_group(current_group_name)
	#if prev_group.size() == highlighted_group.size() and group_leaders.size() == 1:
		#var leader = group_leaders[0]
		#if leader in prev_group and leader in highlighted_group:
			#move_unit(leader, to_position)
			#return
	
	reset_group_affiliation(highlighted_group)
	move_new_unit(to_position)

# Calls down to an indivdual ship to move it. 
func move_unit(unit_leader: Ship, to_position: Vector2) -> void:
	get_tree().call_group(highlight_enemy_name, "highlight_selection", false)
	get_tree().call_group(highlight_enemy_name, "group_remove", highlight_enemy_name)
	unit_leader.set_navigation_position(to_position)
	get_viewport().set_input_as_handled()

func move_new_unit(to_position: Vector2) -> void:
	# 1) Create an array of ships (nodes) from the ships the player currently has selected
	var highlighted_group: Array = get_tree().get_nodes_in_group(highlight_group_name)
	
	# 2) Assign group leader
	# 2a) Arbitrarily assign a group leader to "groups" of 1 or 2 units.
	var new_leader = null
	if highlighted_group.size() > 0 and highlighted_group.size() <= 2:
		new_leader = highlighted_group[0]
	
	# 2b) Find the geometric median of all unit positions and assign the nearest
	# neighoring ship to the median.
	if highlighted_group.size() > 2:
		var unit_positions: Dictionary = {}
		for unit in highlighted_group:
			unit_positions[unit.global_position] = unit
		
		var median: Vector2 = globals.geometric_median_of_objects(unit_positions)
		new_leader = globals.find_unit_nearest_to_median(median, unit_positions)
	
	# 3) Generate and assign a name. Sort the name arrays.
	var new_group_name: StringName 
	if available_group_names.size() > 0:
		new_group_name = available_group_names.pop_back()
	elif available_group_names.size() == 0:
	# iterate a new group name
		new_group_name = StringName("Group " + str(group_iterator))
		group_iterator += 1
	
	taken_group_names.push_back(new_group_name)
	
	# 4) create the group from the currently selected ships. Current_selected_group is full of unique references to ships. Any changes made will not back propagate to highlighted_group and vice versa.
	var current_selected_group: Array = highlighted_group.duplicate()
	current_groups[new_group_name] = current_selected_group
	# ship.group_add() must be called on every individual ship. it does special things like assigning ship.group_name
	get_tree().call_group(highlight_group_name, "group_add", new_group_name)
	new_leader.set_group_leader(true)
	
	# 5) Call down to an individual ship (new_leader).
	move_unit(new_leader, to_position)

# this will require iteration soon
func attack_targets() -> void:
	var highlighted_group: Array = get_tree().get_nodes_in_group(highlight_group_name)
	var targeted_group: Array = get_tree().get_nodes_in_group(highlight_enemy_name)
	var target_group_key: StringName = &" targets"
	var target_key: StringName = &"target"
	get_tree().call_group(highlight_enemy_name, "highlight_selection", true)
	
	var funny_pair: Array = current_groups.values()
	var existing_group: Array = []
	for pair in funny_pair:
		if highlighted_group == pair:
			existing_group = pair
	
	# Alt select and select_units causes a multitude of problems I can't bother to fix.
	if not existing_group.is_empty():
		var leader = null
		for unit in existing_group:
			if unit.group_leader == true:
				leader = unit
		var key_copy: StringName = leader.group_name + target_group_key
		var targets_available = leader.CombatBehaviorTree.blackboard.ret_data(key_copy)
		if targeted_group == targets_available:
			return
	
	var group_leaders: Array = []
	for unit in highlighted_group:
		if unit.group_leader:
			group_leaders.push_back(unit)
	
	reset_group_affiliation(highlighted_group)
	
	var leader: Ship = null
	if highlighted_group.size() > 0 and highlighted_group.size() <= 2:
		leader = highlighted_group[0]
	
	if highlighted_group.size() > 2:
		var unit_positions: Dictionary = {}
		for unit in highlighted_group:
			unit_positions[unit.global_position] = unit
		
		var median: Vector2 = globals.geometric_median_of_objects(unit_positions)
		leader = globals.find_unit_nearest_to_median(median, unit_positions)
	
	# 3) Generate and assign a name. Sort the name arrays.
	var new_group_name: StringName 
	if available_group_names.size() > 0:
		new_group_name = available_group_names.pop_back()
	elif available_group_names.size() == 0:
	# iterate a new group name
		new_group_name = StringName("Group " + str(group_iterator))
		group_iterator += 1
	
	taken_group_names.push_back(new_group_name)
	get_tree().call_group(highlight_group_name, "group_add", new_group_name)
	current_groups[new_group_name] = highlighted_group
	
	target_group_key = leader.group_name + &" targets" 
	var target_idx: int = 0
	for target in targeted_group:
		if target == null:
			targeted_group.remove_at(target_idx)
		target_idx += 1
	
	leader.set_group_leader(true)
	leader.set_blackboard_data(target_group_key, targeted_group)
	get_tree().call_group(new_group_name, "set_combat_ai", true)

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
	
	if selection.size() == 0:
		get_tree().call_group(highlight_enemy_name, "highlight_selection", false)
		get_tree().call_group(highlight_enemy_name, "group_remove", highlight_enemy_name)
		get_tree().call_group(highlight_group_name, "highlight_selection", false)
		get_tree().call_group(highlight_group_name, "group_remove", highlight_group_name)
		current_group_name = &""
		return
	
	var past_group: Array = get_tree().get_nodes_in_group(highlight_group_name)
	for ship in past_group:
		if not ship in selection and ship.is_friendly and attack_group == false:
			ship.highlight_selection(false)
			ship.remove_from_group(highlight_group_name)
	
	var past_enemy_group: Array = get_tree().get_nodes_in_group(highlight_enemy_name)
	for ship in past_enemy_group:
		if not ship in selection and not ship.is_friendly:
			ship.highlight_selection(false)
			ship.remove_from_group(highlight_enemy_name)
	
	for ship in selection:
		if not ship.is_friendly and attack_group == true:
			ship.add_to_group(highlight_enemy_name)
		elif ship.is_friendly and attack_group == false:
			ship.add_to_group(highlight_group_name)
	
	if attack_group:
		attack_targets()
	get_tree().call_group(highlight_group_name, "highlight_selection", true)

# Takes a group of recently selected ships and creates a new group for them.
func reset_group_affiliation(group_select: Array) -> void:
	# removes them if they're already in a group. removes leader status ofc
	for unit: Ship in group_select:
		unit.remove_from_group(unit.group_name)
		var affiliated_group: Array = get_tree().get_nodes_in_group(unit.group_name)
		if unit.group_leader == true and affiliated_group.size() > 0:
			globals.reset_group_leader(unit)
		elif unit.group_leader == true:
			unit.set_group_leader(false)
		unit.group_name = &""
	var count_down: int = taken_group_names.size() - 1
	for group_idx in range(count_down, -1, -1):
		var group_name: StringName = taken_group_names[group_idx]
		var group: Array = get_tree().get_nodes_in_group(group_name)
		if group.is_empty():
			taken_group_names.remove_at(group_idx)
			available_group_names.push_back(group_name)

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
		attack_group = false
		visible = false
	
	var friendly_group: Array = get_tree().get_nodes_in_group("friendly")
	var enemy_group: Array = get_tree().get_nodes_in_group("enemy")
	connect_unit_signals(friendly_group)
	connect_unit_signals(enemy_group)
	
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

func _on_unit_selected(unit: Ship) -> void:
	get_viewport().set_input_as_handled()
	
	var current_selection: Array = get_tree().get_nodes_in_group(current_group_name)
	if current_selection.size() > 1 and unit != prev_selected_ship:
		if unit.group_leader == true:
			globals.reset_group_leader(unit)
	
	get_tree().call_group(highlight_group_name, "highlight_selection", false)
	get_tree().call_group(highlight_group_name, "group_remove", highlight_group_name)
	
	if prev_selected_ship == unit:
		unit.highlight_selection(false)
		prev_selected_ship = null
		return
	
	unit.add_to_group(highlight_group_name)
	unit.highlight_selection(true)
	prev_selected_ship = unit
	reset_box_selection()

func connect_unit_signals(units: Array) -> void:
	for n_unit in units:
		if n_unit == null:
			continue
		if n_unit.is_friendly == true and not n_unit.alt_select.is_connected(_on_alt_select):
			n_unit.alt_select.connect(_on_alt_select.bind(n_unit))
			n_unit.switch_to_manual.connect(_on_switched_to_manual)
			n_unit.ship_selected.connect(_on_unit_selected.bind(n_unit))
		if n_unit.is_friendly == false and not n_unit.alt_select.is_connected(_on_alt_select):
			n_unit.alt_select.connect(_on_alt_select.bind(n_unit))

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
