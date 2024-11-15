extends Node2D

@onready var CombatCamera = $CombatCamera

var camera_drag: bool = false
var zoom_in_limit: Vector2 = Vector2(0.5, 0.5)
var zoom_out_limit: Vector2 = Vector2(1.5, 1.5)
var zoom_value: Vector2 = Vector2.ONE

func _ready() -> void:
	CombatCamera.zoom = zoom_value
	CombatCamera.enabled = false
	visible = false

func _unhandled_input(event):
	if not visible:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and zoom_value < zoom_out_limit:
			zoom_value += Vector2(0.1, 0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and zoom_value > zoom_in_limit:
			zoom_value -= Vector2(0.1, 0.1)
		#elif event.button_index == MOUSE_BUTTON_MIDDLE and CombatCamera.enabled:
			#toggle_camera_drag()
	elif event is InputEventMouseMotion:
		if Input.is_action_pressed("camera drag"):
			CombatCamera.position -= event.relative / CombatCamera.zoom

func _physics_process(delta) -> void:
	if CombatCamera.zoom != zoom_value:
		CombatCamera.zoom = lerp(CombatCamera.zoom, zoom_value, 0.5)

func display_combat_map() -> void:
	if visible == false:
		visible = true
		CombatCamera.enabled = true
	else:
		visible = false
		CombatCamera.enabled = false

func toggle_camera_drag() -> void:
	if camera_drag == false:
		camera_drag = true
	else:
		camera_drag = false
