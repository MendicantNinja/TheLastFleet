extends Node2D

@onready var Camera = $Camera2D
@onready var TacticalCamera = $TacticalCamera
@onready var FleetDeploymentPanel = %FleetDeploymentPanel
@onready var FleetDeploymentList = %FleetDeploymentList
@onready var TacticalMap = %TacticalMap
@onready var All = %All
@onready var Deploy = %Deploy
@onready var Cancel = %Cancel

var ships_in_combat: Array[Ship]

# Box Selection
var dragging: bool = false
var box_selection_start: Vector2 = Vector2.ZERO
var line_color: Color = settings.gui_color
@onready var selection_area: Area2D = %SelectionArea
@onready var selection_shape: CollisionShape2D = %SelectionShape

func _ready() -> void:
	FleetDeploymentList.setup_deployment_screen()
	#settings.swizzle(FleetDeploymentList)
	settings.swizzle(FleetDeploymentPanel)
	settings.swizzle(All)
	settings.swizzle(Deploy)
	settings.swizzle(Cancel)

func _process(delta) -> void:
	queue_redraw()

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
			elif event is InputEventMouseMotion and dragging == true:
				queue_redraw()
			# Camera
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if TacticalCamera.get_zoom() < Vector2(.5, .5):
					TacticalCamera.zoom += Vector2(0.01, 0.01)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if TacticalCamera.get_zoom() > Vector2(0.01, 0.01):
					TacticalCamera.zoom -= Vector2(0.01, 0.01)
		if TacticalMap.visible == false:
			if Camera.enabled == true:
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					if Camera.get_zoom() < Vector2(2.0, 2.0):
						Camera.zoom += Vector2(0.1, 0.1)
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					if Camera.get_zoom() > Vector2(.5, .5):
						Camera.zoom -= Vector2(0.1, 0.1)
	# Keys
	elif event is InputEventKey:
		if (event.keycode == KEY_G and event.is_pressed()):
			if FleetDeploymentPanel.visible == false:
				FleetDeploymentPanel.visible = true
			elif FleetDeploymentPanel.visible == true:
				FleetDeploymentPanel.visible = false
		elif (event.keycode == KEY_TAB and event.is_pressed()):
			tactical_camera()
			TacticalMap.display_tactical_map()

func tactical_camera() -> void:
	if TacticalMap.visible == false:
		TacticalCamera.enabled = true
		Camera.enabled = false
	elif TacticalMap.visible == true:
		TacticalCamera.enabled = false
		Camera.enabled = true
		
		
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
		if object is Ship and object.is_allied == true:
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
