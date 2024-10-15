extends Node2D

@onready var Camera = $Camera2D
@onready var FleetDeployment = %FleetDeployment


func _ready() -> void:
	FleetDeployment.setup_deployment_screen()

func _unhandled_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if Camera.get_zoom() < Vector2(2.0, 2.0):
				Camera.zoom += Vector2(0.1, 0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if Camera.get_zoom() > Vector2(0.1, 0.1):
				Camera.zoom -= Vector2(0.1, 0.1)
	elif event is InputEventKey:
		if (event.keycode == KEY_G and event.is_pressed()):
			if FleetDeployment.visible == false:
				FleetDeployment.visible == true
			elif FleetDeployment.visible == true:
				FleetDeployment.visible == false
