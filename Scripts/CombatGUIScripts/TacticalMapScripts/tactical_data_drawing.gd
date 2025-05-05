extends Node2D
@onready var TacticalMapLayer = %TacticalMapLayer
@onready var TacticalViewport: SubViewport = $".."
@onready var TacticalMapCamera = %TacticalMapCamera
@onready var map_bounds: Vector2 = %PlayableAreaBounds.shape.size


@onready var ship_list: Array[Ship]
@onready var ship_registry: Dictionary = imap_manager.registry_map

@onready var icon_list: Array
@onready var TacticalMapIconScene = load("res://Scenes/GUIScenes/CombatGUIScenes/TacticalMapShipIcon.tscn")

@onready var VisibilityLayer: SubViewport
@onready var DetectionTexture: TextureRect = $VisibilityLayerContainer/VisibilityLayer/DetectionRadius
@onready var detection_list: Array[TextureRect]

# Visuals
var TacticalMapBackground: ColorRect
var conversion_coeffecient_x: float
var conversion_coeffecient_y: float
var grid_size: Vector2
#var sub_line_color: Color = Color8(162, 141, 60, 255)
var line_color: Color = Color8(100, 100, 255, 175)
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
var camera_feed_active: bool = false
var camera_feed_ship: Ship = null # For vid feed. There can be only one!

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

# Manual Control
var manually_controlled_ship: Ship = null # There can be only one!
 
# Weird Stuff
var initial_setup: bool = false

signal switch_maps()

# Called when the node enters the scene tree for the first time.
func _ready():
	TacticalMapBackground = $TacticalMapBackground
	grid_size = Vector2(TacticalMapBackground.size.x, TacticalMapBackground.size.y)
	#%TacticalMapCamera.limit_right = TacticalMapBackground.size.x * 2
	#%TacticalMapCamera.limit_bottom = TacticalMapBackground.size.x * 2
	conversion_coeffecient_x = TacticalMapBackground.size.x/map_bounds.x
	conversion_coeffecient_y = TacticalMapBackground.size.y/map_bounds.y
	
	$FogOfWar.size = TacticalMapBackground.size
	$VisibilityLayerContainer/VisibilityLayer.size = TacticalMapBackground.size
	$FogOfWar.material.set_shader_parameter("visibility_texture", $VisibilityLayerContainer/VisibilityLayer.get_texture())
	
	setup()
	queue_redraw()
	
	for child in $"../../../ButtonList".get_children():
		if child is TextureButton:
			child.pressed.connect(Callable(globals, "play_gui_audio_string").bind("confirm"))
			child.mouse_entered.connect(Callable(globals, "play_gui_audio_string").bind("hover"))
	#stress_testing()
	pass # Replace with function body.

func _unhandled_input(event) -> void:
	# We don't want tactical map taking input when it's not visible.
	if TacticalMapLayer.visible == false:
		return
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("select"):
			box_selection_start = get_global_mouse_position()
		elif Input.is_action_just_released("select") and box_selection_end != Vector2.ZERO:
			select_units()
		elif Input.is_action_just_pressed("m2") and not (Input.is_action_pressed("select") or Input.is_action_pressed("alt_select")):
			var to_position: Vector2 = convert_map_to_realspace(get_global_mouse_position(), map_bounds, grid_size)
			process_move(to_position)
			%TutorialWalkthrough.move_order = true
		elif Input.is_action_just_pressed("zoom in") and TacticalCamera.zoom < zoom_in_limit:
			TacticalCamera.zoom += Vector2(0.05, 0.05)
		elif Input.is_action_just_pressed("zoom out") and TacticalCamera.zoom > zoom_out_limit:
			TacticalCamera.zoom -= Vector2(0.05, 0.05)
	elif event is InputEventMouseMotion:
		if Input.is_action_pressed("select") and box_selection_start > Vector2.ZERO:
			box_selection_end = get_global_mouse_position()
			queue_redraw()
		elif Input.is_action_pressed("camera action"):
			TacticalCamera.position -= event.relative / TacticalCamera.zoom
	elif event is InputEventKey:
		var highlighted_group: Array = get_tree().get_nodes_in_group(highlight_group_name)
		var highlighted_enemy_group: Array = get_tree().get_nodes_in_group(highlight_enemy_name)
		if Input.is_action_pressed("take_manual_control") and TacticalCamera.enabled and prev_selected_ship != null:
			#if self.visible:
			$"../../../ButtonList/ManualControlButton".emit_signal("pressed")
			switch_maps.emit()
			reset_box_selection()
			if manually_controlled_ship != null:
				# Turn off MC for the old ship.
				manually_controlled_ship.toggle_manual_control()
			manually_controlled_ship = prev_selected_ship
			%CombatMap.manually_controlled_unit = manually_controlled_ship
			manually_controlled_ship.toggle_manual_control()
		elif Input.is_action_pressed("camera_feed") and prev_selected_ship !=null:
			#print("Camera feed called")
			$"../../../ButtonList/CameraFeedButton".emit_signal("pressed")
			switch_maps.emit()
			reset_box_selection()
			camera_feed_active = true
			swap_camera_feed(prev_selected_ship)
		elif Input.is_action_pressed("toggle_map"):
			switch_maps.emit()
		elif Input.is_action_pressed("alt_select") and Input.is_action_pressed("select") and highlighted_group.size() > 0:
			attack_group = true
			selection_line_color = Color(Color.CRIMSON)
			queue_redraw()
		elif Input.is_action_just_released("alt_select"):
			if highlighted_group.size() > 0 and highlighted_enemy_group.size() > 0:
				attack_targets()
				%TutorialWalkthrough.attack_order = true
			attack_group = false
			selection_line_color = settings.gui_color
			queue_redraw()
		elif event.keycode == KEY_F1 and event.pressed:
			if $"../../../TutorialText".visible == true:
				$"../../../TutorialText".visible = false
			elif $"../../../TutorialText".visible == false:
				$"../../../TutorialText".visible = true
		elif (event.keycode == KEY_SPACE and event.pressed):
			pause_game()

func pause_game() -> void:
			if get_tree().paused == false:
				get_tree().paused = true
				$"../../../../VariousCanvasPopups/GamePausedText".visible = true
			elif get_tree().paused == true:
				get_tree().paused = false
				$"../../../../VariousCanvasPopups/GamePausedText".visible = false

func connect_unit_signals(units: Array) -> void:
	for n_unit in units:
		if n_unit == null:
			continue
		if n_unit.is_friendly == true and not n_unit.alt_select.is_connected(_on_alt_select):
			n_unit.alt_select.connect(_on_alt_select.bind(n_unit))
			n_unit.ship_selected.connect(_on_unit_selected.bind(n_unit))
		if n_unit.is_friendly == false and not n_unit.alt_select.is_connected(_on_alt_select):
			n_unit.alt_select.connect(_on_alt_select.bind(n_unit))    
																																																									  
#oooooo     oooo ooooo  .oooooo..o ooooo     ooo       .o.       ooooo        
 #`888.     .8'  `888' d8P'    `Y8 `888'     `8'      .888.      `888'        
  #`888.   .8'    888  Y88bo.       888       8      .8"888.      888         
   #`888. .8'     888   `"Y8888o.   888       8     .8' `888.     888         
	#`888.8'      888       `"Y88b  888       8    .88ooo8888.    888         
	 #`888'       888  oo     .d8P  `88.    .8'   .8'     `888.   888       o 
	  #`8'       o888o 8""88888P'     `YbodP'    o88o     o8888o o888ooooood8    

func display_map(map_value: bool) -> void:
	# Show the Tac Map
	if map_value == true:
		if camera_feed_ship != null:
			#print("map value called")
			camera_feed_ship.camera_feed = false
			camera_feed_ship = null
			camera_feed_active = false
		TacticalCamera.enabled = true
		TacticalMapCamera.position = self.position + Vector2(grid_size.x/2, grid_size.y * .9)
		TacticalMapCamera.zoom = Vector2(.15, .15)
		setup()
		%BlackenScreenLayer.visible = true
		%TacticalMapLayer.visible = true
	# Hide the Tac Map
	elif map_value == false:
		TacticalCamera.enabled = false
		attack_group = false
		#$"../..".grab_focus()
		%TacticalMapLayer.visible = false
		%BlackenScreenLayer.visible = false
	  

func swap_camera_feed(ship: Ship) -> void:
	if camera_feed_ship != null:
		camera_feed_ship.camera_feed = false
	camera_feed_ship = ship
	ship.camera_feed = true
	%CombatMap.CombatCamera.position_smoothing_enabled = false
	%CombatMap.CombatCamera.global_position = camera_feed_ship.global_position
	

func setup() -> void:
	#print("setup called")
	# Check if new ships have been added or old ones died
	var ship_arrays: Array = ship_registry.values()
	#print(ship_arrays.size())
	for array in ship_arrays:
		for ship in array:
			if ship_list.has(ship):
				continue
			else:
				ship_list.append(ship)
				var tactical_map_icon: TacticalMapIcon = TacticalMapIconScene.instantiate()
				self.add_child(tactical_map_icon)
				ship.tactical_map_icon = tactical_map_icon
				tactical_map_icon.setup(ship)
				icon_list.append(tactical_map_icon)
				
				var texture_appended: TextureRect = DetectionTexture.duplicate()
				$VisibilityLayerContainer/VisibilityLayer.add_child(texture_appended)
				detection_list.append(texture_appended)
				if ship.is_friendly == false: # We dont want enemies removing the fog of war!
					ship.is_revealed = false 
					texture_appended.visible = false
					continue
				else:
					ship.is_revealed = true
				var detection_diameter_tacmap: int = ship.sensor_strength * 2 * conversion_coeffecient_x
				texture_appended.texture.width = detection_diameter_tacmap
				texture_appended.texture.height = detection_diameter_tacmap
				#texture_appended.pivot_offset = -(texture_appended.size) 
				

				
	var friendly_group: Array = get_tree().get_nodes_in_group("friendly")
	var enemy_group: Array = get_tree().get_nodes_in_group("enemy")
	connect_unit_signals(friendly_group)
	connect_unit_signals(enemy_group)
	get_tree().call_group("enemy", "display_icon", visible)
	get_tree().call_group("friendly", "display_icon", visible)    

	update()

func update() -> void:
	#print("update")
	if prev_selected_ship == null: 
		$"../../../ButtonList/ManualControlButton".disabled = true
		$"../../../ButtonList/CameraFeedButton".disabled = true
	else:
		$"../../../ButtonList/ManualControlButton".disabled = false
		$"../../../ButtonList/CameraFeedButton".disabled = false
	for i in range(icon_list.size() - 1, -1, -1):
		if icon_list[i] == null or icon_list[i].assigned_ship == null:
			icon_list[i].queue_free()
			icon_list.erase(icon_list[i])
			detection_list[i].queue_free()
			detection_list.erase(detection_list[i])
	
	for i in icon_list.size():
		var icon = icon_list[i]
		var radius = detection_list[i]
		icon.position = convert_realspace_to_map(icon.assigned_ship.global_position, map_bounds, grid_size)
		radius.position = icon.position + Vector2(-radius.size.x/2, -radius.size.y/2)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#if self.visible == true and Engine.get_physics_frames() % 3 == 0:
	update()
	# Populate the map because ship registration isn't instantaneous as of 2/18/24
	if initial_setup == false and Engine.get_physics_frames() % 62 == 0:
			setup()
			initial_setup = true

func convert_realspace_to_map(global_pos: Vector2, global_map_size: Vector2, tactical_map_size: Vector2) -> Vector2:
	return Vector2(
		global_pos.x * (tactical_map_size.x / global_map_size.x),
		global_pos.y * (tactical_map_size.y / global_map_size.y)
	)

func convert_map_to_realspace(map_position: Vector2, global_map_size: Vector2, tactical_map_size: Vector2) -> Vector2:
	return Vector2(
		map_position.x * ( global_map_size.x/tactical_map_size.x),
		map_position.y * ( global_map_size.y/tactical_map_size.y)
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

 #.oooooo..o oooooooooooo ooooo        oooooooooooo   .oooooo.   ooooooooooooo 
#d8P'    `Y8 `888'     `8 `888'        `888'     `8  d8P'  `Y8b  8'   888   `8 
#Y88bo.       888          888          888         888               888      
 #`"Y8888o.   888oooo8     888          888oooo8    888               888      
	 #`"Y88b  888    "     888          888    "    888               888      
#oo     .d8P  888       o  888       o  888       o `88b    ooo       888      
#8""88888P'  o888ooooood8 o888ooooood8 o888ooooood8  `Y8bood8P'      o888o     
																		
																		  
func select_units() -> void:
	var size: Vector2 = abs(box_selection_end - box_selection_start)
	var area_position: Vector2 = get_rect_start_position()
	
	var selection_icons: Array[TacticalMapIcon] = get_icons_in_box_selection(Rect2(area_position, size))
	var selection: Array[Ship]
	for icon in selection_icons:
		selection.append(icon.assigned_ship)
	#print("select_units called ", selection_icons, "and selection is ", selection)
	reset_box_selection()
	
	if selection.size() == 0:
		get_tree().call_group(highlight_enemy_name, "highlight_selection", false)
		get_tree().call_group(highlight_enemy_name, "group_remove", highlight_enemy_name)
		get_tree().call_group(highlight_group_name, "highlight_selection", false)
		get_tree().call_group(highlight_group_name, "group_remove", highlight_group_name)
		current_group_name = &""
		return
	globals.play_gui_audio_string("selected")
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
	# Whatever is still selected, highlight it.
	get_tree().call_group(highlight_group_name, "highlight_selection", true)
	
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
	
	# Called only on box select
	
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
	

func _on_unit_selected(unit: Ship) -> void:
	#print("on unit selected")
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

#ooo        ooooo   .oooooo.   oooooo     oooo oooooooooooo ooo        ooooo oooooooooooo ooooo      ooo ooooooooooooo 
#`88.       .888'  d8P'  `Y8b   `888.     .8'  `888'     `8 `88.       .888' `888'     `8 `888b.     `8' 8'   888   `8 
 #888b     d'888  888      888   `888.   .8'    888          888b     d'888   888          8 `88b.    8       888      
 #8 Y88. .P  888  888      888    `888. .8'     888oooo8     8 Y88. .P  888   888oooo8     8   `88b.  8       888      
 #8  `888'   888  888      888     `888.8'      888    "     8  `888'   888   888    "     8     `88b.8       888      
 #8    Y     888  `88b    d88'      `888'       888       o  8    Y     888   888       o  8       `888       888      
#o8o        o888o  `Y8bood8P'        `8'       o888ooooood8 o8o        o888o o888ooooood8 o8o        `8      o888o   


func process_move(to_position: Vector2) -> void:
	# input, process_move, IF already existing move_unit, 
	# else if not already existing: move_new_unit, reset_group_affiliation, move_unit
	var highlighted_group: Array = get_tree().get_nodes_in_group(highlight_group_name)
	if highlighted_group.size() == 0:
		return
	globals.play_gui_audio_string("order")
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
	var leader_key: StringName = &"leader"
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
		
		var median: Vector2 = globals.geometric_median_of_objects(unit_positions.keys())
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
	get_tree().call_group(new_group_name, &"set_blackboard_data", leader_key, new_leader)
	# 5) Call down to an individual ship (new_leader).
	move_unit(new_leader, to_position)
	  #.o.       ooooooooooooo ooooooooooooo       .o.         .oooooo.   oooo    oooo 
	 #.888.      8'   888   `8 8'   888   `8      .888.       d8P'  `Y8b  `888   .8P'  
	#.8"888.          888           888          .8"888.     888           888  d8'    
   #.8' `888.         888           888         .8' `888.    888           88888[      
  #.88ooo8888.        888           888        .88ooo8888.   888           888`88b.    
 #.8'     `888.       888           888       .8'     `888.  `88b    ooo   888  `88b.  
#o88o     o8888o     o888o         o888o     o88o     o8888o  `Y8bood8P'  o888o  o888o 


func attack_targets() -> void:
	var highlighted_group: Array = get_tree().get_nodes_in_group(highlight_group_name)
	var targeted_group: Array = get_tree().get_nodes_in_group(highlight_enemy_name)
	get_tree().call_group(highlight_enemy_name, "highlight_selection", true)
	
	var funny_pair: Array = current_groups.values()
	var existing_group: Array = []
	for pair in funny_pair:
		if highlighted_group == pair:
			existing_group = pair
	
	var leader = null
	# Alt select and select_units causes a multitude of problems I can't bother to fix.
	if not existing_group.is_empty():
		globals.play_gui_audio_string("attack")
		for unit in existing_group:
			if unit.group_leader == true:
				leader = unit
				break
		var targets_available: Array = leader.targeted_units
		if targets_available == targeted_group:
			return
	
	for unit in highlighted_group:
		if unit.group_leader == true:
			unit.set_group_leader(false)
	
	reset_group_affiliation(highlighted_group)
	
	if highlighted_group.size() > 0 and highlighted_group.size() <= 2:
		leader = highlighted_group[0]
	
	if highlighted_group.size() > 2:
		var unit_positions: Dictionary = {}
		for unit in highlighted_group:
			unit_positions[unit.global_position] = unit
		
		var median: Vector2 = globals.geometric_median_of_objects(unit_positions.keys())
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
	current_groups[new_group_name] = highlighted_group
	get_tree().call_group(highlight_group_name, "group_add", new_group_name)
	get_tree().call_group(new_group_name, &"set_targets", targeted_group)
	leader.set_group_leader(true)


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
	
func _on_alt_select(ship: Ship) -> void:
	print("alt select called")
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


# I could make this a global with a callable as the parameter.
func performance_testing():
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

func delayed_setup_call():
	var timer = Timer.new()
	add_child(timer)  # Add to scene tree so it runs
	timer.wait_time = 1 # 2 seconds
	timer.one_shot = true  # Runs once
	timer.start()
	timer.timeout.connect(_delayed_setup_timeout.bind(timer))  # Bind to remove after use

func _delayed_setup_timeout(timer):
	setup()
	timer.queue_free()  # Remove the timer from the scene
