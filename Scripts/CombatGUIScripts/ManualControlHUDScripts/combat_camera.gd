extends Camera2D

var camera_drag: bool = false
var zoom_max: Vector2 = Vector2(0.5, 0.5)
var zoom_min: Vector2 = Vector2(1.5, 1.5)
var zoom_value: Vector2 = Vector2.ONE

func _ready() -> void:
	zoom = zoom_value

func _unhandled_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if zoom_value < zoom_min:
				zoom_value += Vector2(0.1, 0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if zoom_value > zoom_max:
				zoom_value -= Vector2(0.1, 0.1)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			toggle_camera_drag()
	elif event is InputEventMouseMotion:
		if camera_drag:
			position -= event.relative / zoom

func _physics_process(delta) -> void:
	if zoom != zoom_value:
		zoom = lerp(zoom, zoom_value, delta)

func toggle_camera_drag() -> bool:
	if not camera_drag:
		camera_drag = true
	else:
		camera_drag = false
	return camera_drag
