extends TextureButton
@onready var KeyBinding: RichTextLabel = $Keybinding
# Called when the node enters the scene tree for the first time.
func _ready():
	var binding_name = globals.convert_input_to_string(&"take_control", "green")
	$Keybinding.text = binding_name

func _pressed() -> void:
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _unhandled_input(event):
		#if event is InputEventMouseButton:
			#if Input.is_action_just_pressed("select"):
				#print("input on button detected")
			#var button_rect = Rect2(global_position, Vector2(100, 100))
			#if button_rect.has_point(get_global_mouse_position()):
				#get_viewport().set_input_as_handled()
	pass
