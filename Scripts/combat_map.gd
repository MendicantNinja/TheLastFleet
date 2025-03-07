extends Node2D

const ManualControlCamera = preload("res://Scenes/GUIScenes/CombatGUIScenes/ManualControlCamera.tscn")

@onready var CombatCamera = $CombatCamera
@onready var Cancel = %Cancel
var manually_controlled_unit: Ship = null # Different from prev selected unit in tac map. Closer meaning is "manually controlled unit"
var zoom_in_limit: Vector2 = Vector2(1.5, 1.5)
var zoom_out_limit: Vector2 = Vector2(.5, .5)
var camera_position: Vector2 = Vector2.ZERO
var zoom_min: Vector2 = Vector2(1.5, 1.5)
var zoom_value: Vector2 = Vector2(0.1, 0.1)
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
	var map_center: Vector2 = Vector2(map_bounds.x / 2, map_bounds.y / 2)
	CombatCamera.position = map_center
	if settings.dev_mode == true:
		zoom_out_limit = Vector2(.01, .01)

func _unhandled_input(event):
	if %TacticalMapLayer.visible:
		return
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("zoom in") and zoom_value < zoom_in_limit and CombatCamera.enabled:
			zoom_value += Vector2(0.01, 0.01)
		elif Input.is_action_just_pressed("zoom out") and zoom_value > zoom_out_limit and CombatCamera.enabled:
			zoom_value -= Vector2(0.01, 0.01)
		if Input.is_action_just_released("camera action") and CombatCamera.enabled and manually_controlled_unit != null:
			manually_controlled_unit.toggle_manual_camera_freelook(false)
	elif event is InputEventMouseMotion:
		#Middle Mouse Button Scrolling
		if Input.is_action_pressed("camera action") and CombatCamera.enabled:
			#print(manually_controlled_unit)
			CombatCamera.global_position -= event.relative / CombatCamera.zoom
			if manually_controlled_unit != null:
				manually_controlled_unit.toggle_manual_camera_freelook(true)
	#on middle mouse button released
	elif event is InputEventKey:
		if event.keycode == KEY_TAB and event.pressed:
			switch_maps.emit()

func _physics_process(delta) -> void:
	if CombatCamera.zoom != zoom_value:
		CombatCamera.zoom = lerp(CombatCamera.zoom, zoom_value, 0.5)
	#if manually_controlled_unit != null and CombatCamera.position != manually_controlled_unit.global_position:
		#CombatCamera.position = manually_controlled_unit.global_position

func display_map(map_value: bool) -> void:
	if map_value == true:
		CombatCamera.enabled = true
		
	elif map_value == false:
		CombatCamera.enabled = false
		
	#var friendly_group: Array = get_tree().get_nodes_in_group("friendly")
	#for ship in friendly_group:
		#if not ship.request_manual_camera.is_connected(set_manual_camera):
			#ship.request_manual_camera.connect(set_manual_camera.bind(ship))

func set_manual_camera(unit: Ship) -> void:
	if manually_controlled_unit and manually_controlled_unit != unit and manually_controlled_unit != null:
		manually_controlled_unit.toggle_manual_control()
		manually_controlled_unit.toggle_manual_aim(manually_controlled_unit.all_weapons, false) # Needed to shut off weapons because the code is fucked.
	manually_controlled_unit = unit # Discards the old unit, brings in the new.

func _add_player_ship(ship) -> void:
	add_child(ship)
