extends Control
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# If texture is assigned in a parent on ready, then we cannot access the texture here.
func create_radius(radius: Vector2i) -> void: 
	#set_anchors_preset(PRESET_TOP_LEFT)
	custom_minimum_size = radius * .6
	size = radius * .6
	position -= size/2
	#set_anchors_preset(PRESET_FULL_RECT)
	#pivot_offset = custom_minimum_size/2
	

	pass


#func _gui_input(event) -> void:
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#print("WeaponSlotRefitArea clicked")

func _process(delta):
	pass
