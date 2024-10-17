extends Node2D

@onready var Camera = $Camera2D
@onready var FleetDeploymentPanel = %FleetDeploymentPanel
@onready var FleetDeploymentList = %FleetDeploymentList
@onready var All = %All
@onready var Deploy = %Deploy
@onready var Cancel = %Cancel

func _ready() -> void:
	FleetDeploymentList.setup_deployment_screen()
	#settings.swizzle(FleetDeploymentList)
	settings.swizzle(FleetDeploymentPanel)
	settings.swizzle(All)
	settings.swizzle(Deploy)
	settings.swizzle(Cancel)



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
			if FleetDeploymentPanel.visible == false:
				FleetDeploymentPanel.visible = true
			elif FleetDeploymentPanel.visible == true:
				FleetDeploymentPanel.visible = false
