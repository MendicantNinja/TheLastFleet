extends CanvasLayer

#CanvasLayer # Provide transform needed for child control's anchor to do Full Rect
#-> CenterContainer - Set Anchor Preset to Full Rect
#--> Control # A control node that restrict to CenterContainer Parent to be centered on the middle
#---> SubviewportContainer # Your subviewport here, now just move the camera inside like how you want to pan it 
@onready var ManualControlButton = $ManualControlButton
@onready var CameraFeedButton = $CameraFeedButton


func _unhandled_input(event):
	if event is InputEventKey:
		if event.keycode == KEY_F1 and event.pressed:
			toggle_visible()
			

func toggle_visible() -> void:
	if visible == true:
		%TacticalDataDrawing.display()
		visible = false
	elif visible == false:
		%TacticalDataDrawing.display()
		visible = true
		$TacticalViewportContainer.grab_focus()
		
# Called when the node enters the scene tree for the first time.
func _ready():
	# Done to avoid having to double tap to get it to display.
	toggle_visible() # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
