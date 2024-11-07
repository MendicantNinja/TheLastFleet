extends Node2D

@onready var CombatCamera = $CombatCamera
@onready var TacticalCamera = $TacticalCamera
@onready var FleetDeploymentPanel = %FleetDeploymentPanel
@onready var FleetDeploymentList = %FleetDeploymentList
@onready var All = %All
@onready var Deploy = %Deploy
@onready var Cancel = %Cancel

@onready var TacticalMap = %TacticalMap
@onready var PlayableAreaBounds = $PlayableArea/PlayableAreaBounds


var ships_in_combat: Array[Ship]
var controlled_ship: Ship

var free_look: bool = false
var pan_threshold: int = 10 # Distance from the screen edges to start panning
var pan_step: int  = 8 # Speed of camera movement

var camera_drag: bool = false
var zoom_max: Vector2 = Vector2(0.5, 0.5)
var zoom_min: Vector2 = Vector2(2.0, 2.0)
var zoom_value: Vector2 = Vector2.ONE

var tactical_camera_drag: bool = false
var tactical_zoom_max: Vector2 = Vector2(0.09, 0.09)
var tactical_zoom_min: Vector2 = Vector2(1.5, 1.5)
var tactical_zoom_value: Vector2 = Vector2(.3, .3)




func _physics_process(delta) -> void:
	if CombatCamera.zoom != zoom_value:
		CombatCamera.zoom = lerp(CombatCamera.zoom, zoom_value, delta)
	if TacticalCamera.zoom != tactical_zoom_value:
		TacticalCamera.zoom = lerp(TacticalCamera.zoom, tactical_zoom_value, delta)

# Box Selection
var dragging: bool = false
var box_selection_start: Vector2 = Vector2.ZERO
var line_color: Color = settings.gui_color
@onready var selection_area: Area2D = %SelectionArea
@onready var selection_shape: CollisionShape2D = %SelectionShape

func _ready() -> void:
	# Camera
	var extra_bounds: int = 3000
	TacticalCamera.limit_top = -extra_bounds
	TacticalCamera.limit_left = -extra_bounds
	TacticalCamera.limit_right = PlayableAreaBounds.shape.size.x + extra_bounds
	TacticalCamera.limit_bottom = PlayableAreaBounds.shape.size.y + extra_bounds
	TacticalCamera.zoom = tactical_zoom_value
	
	CombatCamera.limit_top = -extra_bounds
	CombatCamera.limit_left = -extra_bounds
	CombatCamera.limit_right = PlayableAreaBounds.shape.size.x + extra_bounds
	CombatCamera.limit_bottom = PlayableAreaBounds.shape.size.y + extra_bounds
	CombatCamera.zoom = zoom_value
	
	
	# GUI
	FleetDeploymentList.setup_deployment_screen()
	#settings.swizzle(FleetDeploymentList)
	settings.swizzle(FleetDeploymentPanel)
	settings.swizzle(All)
	settings.swizzle(Deploy)
	settings.swizzle(Cancel)
	
	# Data
	var friendly_group: Array = get_tree().get_nodes_in_group("friendly")
	for friendly_ship in friendly_group:
		connect_ship_signals(friendly_ship)
	pass

func _process(delta) -> void:
	queue_redraw()
	#pan()
	#var viewport_size = get_viewport().size
	#var local_mouse_pos: Vector2 = get_global_mouse_position()
	#if TacticalMap.visible == false:
		#if local_mouse_pos.x < pan_threshold:
			#CombatCamera.position.x -= pan_step
		#elif local_mouse_pos.x > viewport_size.x - pan_threshold:
			#CombatCamera.position.x += pan_step

func _unhandled_input(event) -> void:
	if event is InputEventMouseButton: 
		if TacticalMap.visible == true:
			if event.button_index == MOUSE_BUTTON_LEFT: 
				# If the mouse was clicked, deselect all selected units (unless ctrl is pressed) and start dragging.
				if event.pressed == true:
					dragging = true
					box_selection_start = get_global_mouse_position()
					if Input.is_key_pressed(KEY_CTRL):
						return 
					for ship in ships_in_combat:
						ship.ship_select = false # Deselects all selected ships UNLESS ctrl is pressed or a child ship node has handled the left click input.
				# If the Lmouse is released and is dragging, stop dragging
				elif dragging:
					select_units()
					box_selection_start = Vector2.ZERO
					dragging = false
					queue_redraw()
			# If the mouse is dragging and is not released or clicked or anything redraw the selection rectangle.
			#Camera stuff
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if tactical_zoom_value <  tactical_zoom_min:
					tactical_zoom_value += Vector2(0.03, 0.03)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if tactical_zoom_value >  tactical_zoom_max:
					tactical_zoom_value -= Vector2(0.03, 0.03)
			elif event.button_index == MOUSE_BUTTON_MIDDLE:
				toggle_tactical_camera_drag()
		if TacticalMap.visible == false:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if zoom_value < zoom_min:
					zoom_value += Vector2(0.1, 0.1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if zoom_value > zoom_max:
					zoom_value -= Vector2(0.1, 0.1)
			elif event.button_index == MOUSE_BUTTON_MIDDLE:
				toggle_camera_drag()
	elif event is InputEventMouseMotion:
		if dragging == true:
				queue_redraw()
		if camera_drag:
			CombatCamera.position -= event.relative / CombatCamera.zoom
		elif tactical_camera_drag:
			TacticalCamera.position -= event.relative/ TacticalCamera.zoom
	# Keys
	elif event is InputEventKey:
		if (event.keycode == KEY_G and event.is_pressed()):
			if FleetDeploymentPanel.visible == false:
				FleetDeploymentPanel.visible = true
			elif FleetDeploymentPanel.visible == true:
				FleetDeploymentPanel.visible = false
		elif (event.keycode == KEY_TAB and event.is_pressed()):
			TacticalMap.display_tactical_map()

func tactical_camera() -> void:
	if TacticalMap.visible == false:
		TacticalCamera.enabled = true
		camera_drag = false
		CombatCamera.enabled = false
	elif TacticalMap.visible == true:
		TacticalCamera.enabled = false
		tactical_camera_drag = false
		CombatCamera.enabled = true
		
func pan() -> void:
	pass
# Box Selection Stuff.
func _draw() -> void:
	if box_selection_start == Vector2.ZERO or TacticalMap.visible == false or dragging == false: 
		return
	var end: Vector2 = get_global_mouse_position()
	var start: Vector2 = box_selection_start
	draw_rect(Rect2(start, end - start), settings.gui_color, false, 6, true)

func select_units() -> void:
	var size: Vector2 = abs(get_global_mouse_position() - box_selection_start)
	var area_position: Vector2 = get_rect_start_position()
	selection_area.global_position = area_position
	selection_shape.global_position = area_position + size/2
	selection_shape.shape.size = size
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	for object in selection_area.get_overlapping_bodies():
		if object is Ship and object.is_friendly == true:
			#if object.ship_select == true: # Already selected? Deselect.
				#object.ship_select = false
			object.ship_select = true

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
	pass

func toggle_camera_drag() -> bool:
	if not camera_drag:
		camera_drag = true
	else:
		camera_drag = false
	return camera_drag
	
func toggle_tactical_camera_drag() -> bool:
	if not tactical_camera_drag:
		tactical_camera_drag = true
	else:
		tactical_camera_drag = false
	return tactical_camera_drag
# Connect any signals at the start of the scene to ensure that all friendly and enemy ships
# are more than capable of signaling to each other changes to specific local scene information.
# Currently it only handles signals for friendly ships but it would take little to no effort to
# expand this for both. Ideally, we only use this to connect signals that are required for BOTH
# enemies and friendlies. 
func connect_ship_signals(friendly_ship: Ship) -> void:
	var enemy_group: Array = get_tree().get_nodes_in_group("enemy")
	for ship in enemy_group:
		ship.ship_targeted.connect(friendly_ship._on_ship_targeted)
