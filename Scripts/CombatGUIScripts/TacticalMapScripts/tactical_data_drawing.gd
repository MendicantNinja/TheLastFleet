extends Node2D
@onready var TacticalViewport: SubViewport = $".."
@onready var TacticalMapCamera = %TacticalMapCamera
@onready var map_bounds: Vector2 = %PlayableAreaBounds.shape.size

@onready var ship_registry: Array[Ship]
@onready var ship_dictionary: Dictionary = imap_manager.registry_map

@onready var icon_list: Array
@onready var TacticalMapIconScene = load("res://Scenes/GUIScenes/CombatGUIScenes/TacticalMapShipIcon.tscn")

# Visuals
var TacticalMapBackground: ColorRect 
var grid_size: Vector2
#var sub_line_color: Color = Color8(162, 141, 60, 255)
var line_color: Color = Color8(255, 255, 255, 125)
var line_width: int = 9
var sub_line_width: int = 5

# Box Selection
var box_selection_start: Vector2 = Vector2.ZERO
var box_selection_end: Vector2 = Vector2.ZERO
var selection_line_color: Color = Color8(75, 225, 25) #settings.gui_color

# Camera
var zoom_in_limit: Vector2 = Vector2(1.0, 1.0)
var zoom_out_limit: Vector2 = Vector2(0.15, 0.15) 
@onready var TacticalCamera: Camera2D = %TacticalMapCamera

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

signal switch_maps()

# Called when the node enters the scene tree for the first time.
func _ready():
	TacticalMapBackground = $TacticalMapBackground
	grid_size = Vector2(TacticalMapBackground.size.x, TacticalMapBackground.size.y)
	#%TacticalMapCamera.limit_right = TacticalMapBackground.size.x * 2
	#%TacticalMapCamera.limit_bottom = TacticalMapBackground.size.x * 2
	setup()
	queue_redraw()
	#stress_testing()
	pass # Replace with function body.

func _unhandled_input(event) -> void:
	if event is InputEventMouseButton:
		
		if Input.is_action_just_pressed("select"):
			box_selection_start = get_global_mouse_position()
		elif Input.is_action_just_released("select") and box_selection_end != Vector2.ZERO:
			select_units()
		elif Input.is_action_just_pressed("zoom in") and TacticalCamera.zoom < zoom_in_limit:
			TacticalCamera.zoom += Vector2(0.05, 0.05)
		elif Input.is_action_just_pressed("zoom out") and TacticalCamera.zoom > zoom_out_limit:
			TacticalCamera.zoom -= Vector2(0.05, 0.05)
	elif event is InputEventMouseMotion:
		if Input.is_action_pressed("select") and box_selection_start > Vector2.ZERO:
			box_selection_end = get_global_mouse_position()
			queue_redraw()
		elif Input.is_action_pressed("camera action"):
			#print("subviewport input event mouse button called to pan")
			TacticalCamera.position -= event.relative / TacticalCamera.zoom


func display() -> void:
	TacticalMapCamera.position = self.position + Vector2(grid_size.x/2, grid_size.y * .9)
	TacticalMapCamera.zoom = Vector2(.15, .15)
	setup()

func setup() -> void:
	#ship_registry.clear()
	# Check if new ships have been added
	var ship_arrays: Array = ship_dictionary.values()
	for array in ship_arrays:
		for ship in array:
			if ship_registry.has(ship):
				continue
			else:
				ship_registry.append(ship)
				var tactical_map_icon: TextureButton = TacticalMapIconScene.instantiate()
				self.add_child(tactical_map_icon)
				tactical_map_icon.setup(ship)
				icon_list.append(tactical_map_icon)
	update()

func update() -> void:
	#print("update")
	for icon in icon_list:
		icon.position = convert_position(icon.assigned_ship.global_position, map_bounds, grid_size)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if self.visible == true and Engine.get_physics_frames() % 10 == 0:
		update()
		if Engine.get_physics_frames() % 60 == 0:
			setup()

func convert_position(global_pos: Vector2, global_map_size: Vector2, tactical_map_size: Vector2) -> Vector2:
	return Vector2(
		global_pos.x * (tactical_map_size.x / global_map_size.x),
		global_pos.y * (tactical_map_size.y / global_map_size.y)
	)

func _draw():
	var grid_square_size: int = 900
	var sub_square_size: = 300
	
	 #Draw Subgrid Lines
	for i in range (grid_size.x/sub_square_size+1): #Draw Vertical N/S Lines
		draw_line(Vector2(i*sub_square_size, 0), Vector2(i*sub_square_size, grid_size.y), line_color, sub_line_width, true) 
	
	for i in range (grid_size.y/sub_square_size+1): #Draw Horizontal W/E Lines
		draw_line(Vector2(0, i*sub_square_size), Vector2(grid_size.x, i*sub_square_size), line_color, sub_line_width, true)
	
	# Draw Large Cell Lines
	for i in range (grid_size.x/grid_square_size+1): #Draw Vertical N/S Lines
		draw_line(Vector2(i*grid_square_size, 0), Vector2(i*grid_square_size, grid_size.y), line_color, line_width, true) 
	
	for i in range (grid_size.y/grid_square_size+1): #Draw Horizontal W/E Lines
			draw_line(Vector2(0, i*grid_square_size), Vector2(grid_size.x, i*grid_square_size), line_color, line_width, true)
	
	if box_selection_start == Vector2.ZERO or visible == false: 
		return
	var end: Vector2 = get_global_mouse_position()
	var start: Vector2 = box_selection_start
	
	draw_rect(Rect2(start, end - start), selection_line_color, false, 6, true) 


func get_icons_in_box_selection(rect: Rect2) -> Array[TacticalMapIcon]:
	var selected_controls: Array[TacticalMapIcon] = []
	# Iterate through all children recursively
	for control in self.get_children():
		if control is TacticalMapIcon:
			var control_rect = Rect2(control.global_position, control.size)
	# Check if the control's rect overlaps with selection
			if rect.intersects(control_rect):
				selected_controls.append(control)
	return selected_controls
	
func select_units() -> void:
	#print("select_units called")
	var size: Vector2 = abs(box_selection_end - box_selection_start)
	var area_position: Vector2 = get_rect_start_position()
	
	var selection: Array[TacticalMapIcon] = get_icons_in_box_selection(Rect2(area_position, size))
	reset_box_selection()
	if selection.size() == 0:
		get_tree().call_group(highlight_enemy_name, "highlight_selection", false)
		get_tree().call_group(highlight_enemy_name, "group_remove", highlight_enemy_name)
		get_tree().call_group(highlight_group_name, "highlight_selection", false)
		get_tree().call_group(highlight_group_name, "group_remove", highlight_group_name)
		current_group_name = &""
		return
		#for icon in selection:
			#icon.Outline.button_pressed = false
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
	#add in when adding back attack
	#if attack_group:
		#attack_targets()
	get_tree().call_group(highlight_group_name, "highlight_selection", true)
	for icon in selection:
		icon.Outline.button_pressed = true
	
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

func stress_testing():
	var start:int
	var end:int
	start = Time.get_ticks_msec()
	for i in 10000 :
		%TacticalMapCamera.offset.x = 0
	end = Time.get_ticks_msec()
	print("time ms : " + str(end - start))

	var ob: Camera2D =  %TacticalMapCamera
	start = Time.get_ticks_msec()
	for i in 10000 :
		ob.offset.x = 0
	end = Time.get_ticks_msec()
	print("time ms : " + str(end - start))
