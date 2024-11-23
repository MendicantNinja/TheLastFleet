extends Node2D

const ManualControlCamera = preload("res://Scenes/GUIScenes/CombatGUIScenes/ManualControlCamera.tscn")

@onready var CombatCamera = $CombatCamera
@onready var Cancel = %Cancel
var prev_selected_unit: Ship = null
var zoom_in_limit: Vector2 = Vector2(1.5, 1.5)
var zoom_out_limit: Vector2 = Vector2(0.3, 0.3)
var camera_position: Vector2 = Vector2.ZERO
var zoom_min: Vector2 = Vector2(1.5, 1.5)
var zoom_value: Vector2 = Vector2.ONE
@onready var map_bounds: Vector2 = %PlayableAreaBounds.shape.size

signal switch_maps()

func _ready() -> void:
	# Camera
	CombatCamera.zoom = zoom_value
	var extra_bounds: int = 3000
	CombatCamera.limit_top = -extra_bounds
	CombatCamera.limit_left = -extra_bounds
	CombatCamera.limit_right = map_bounds.x + extra_bounds
	CombatCamera.limit_bottom = map_bounds.y + extra_bounds

func _unhandled_input(event):
	if not visible:
		return
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("zoom in") and zoom_value < zoom_in_limit and CombatCamera.enabled:
			zoom_value += Vector2(0.1, 0.1)
		elif Input.is_action_just_pressed("zoom out") and zoom_value > zoom_out_limit and CombatCamera.enabled:
			zoom_value -= Vector2(0.1, 0.1)
	elif event is InputEventMouseMotion:
		if Input.is_action_pressed("camera action") and CombatCamera.enabled:
			CombatCamera.position -= event.relative / CombatCamera.zoom
	elif event is InputEventKey:
		if event.keycode == KEY_TAB and event.pressed:
			switch_maps.emit()

func toggle_cameras() -> void:
	pass

func _physics_process(delta) -> void:
	if CombatCamera.zoom != zoom_value:
		CombatCamera.zoom = lerp(CombatCamera.zoom, zoom_value, 0.5)

func display_map(map_value: bool) -> void:
	if map_value == true:
		visible = true
		CombatCamera.enabled = true
		
	elif map_value == false:
		visible = false
		CombatCamera.enabled = false
		
	var friendly_group: Array = get_tree().get_nodes_in_group("friendly")
	for ship in friendly_group:
		if not ship.request_manual_camera.is_connected(set_manual_camera):
			ship.request_manual_camera.connect(set_manual_camera.bind(ship))

func set_manual_camera(unit: Ship) -> void:
	if prev_selected_unit and prev_selected_unit != unit:
		prev_selected_unit.toggle_manual_control()
	
	CombatCamera.enabled = false
	unit.add_manual_camera(ManualControlCamera.instantiate(), zoom_value)
	unit.camera_removed.connect(_on_camera_removed.bind(unit))
	prev_selected_unit = unit

func _on_camera_removed(n_zoom_value: Vector2, offset: Vector2, unit: Ship) -> void:
	CombatCamera.enabled = true
	CombatCamera.position = offset/2
	zoom_value = n_zoom_value
	unit.camera_removed.disconnect(_on_camera_removed)
