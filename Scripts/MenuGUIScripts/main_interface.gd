extends Control


@onready var Fleet = %"(F)leet"
@onready var Refit = %"R(efit)"
@onready var Map = %"(M)ap"
@onready var Inventory = %"(I)nventory"

@onready var FleetView = %FleetView
@onready var RefitView = %RefitView
@onready var MapView
@onready var InventoryView


func _unhandled_input(event) -> void:
	if event is InputEventKey:
		if (event.keycode == KEY_F and event.is_pressed()):
			indicate_selected_button(Fleet)
		elif (event.keycode == KEY_R and event.is_pressed()):
			indicate_selected_button(Refit)
		elif (event.keycode == KEY_M and event.is_pressed()):
			swap_gui()
			indicate_selected_button(Map)
		elif (event.keycode == KEY_I and event.is_pressed()):
			swap_gui()
			indicate_selected_button(Inventory)
#
func connect_buttons_lazy() -> void:
	for child in $CanvasLayer/HBoxContainer.get_children():
		if child is TextureButton:
			child.pressed.connect(Callable(globals, "play_gui_audio_string").bind("select"))
			child.mouse_entered.connect(Callable(globals, "play_gui_audio_string").bind("hover"))


# Hide all GUI
func indicate_selected_button(p_control: Control) -> void:
	p_control.emit_signal("pressed")
	settings.swizzle(Fleet)
	settings.swizzle(Refit)
	settings.swizzle(Map)
	settings.swizzle(Inventory)
	settings.swizzle_and_brighten(p_control, settings.gui_color)
	
	if p_control == Fleet:
		swap_gui(FleetView)
	if p_control == Refit:
		swap_gui(RefitView)

func swap_gui(p_control: Control = FleetView) -> void:
	for child in get_children():
		if child is CanvasLayer or child == p_control:
			continue
		else:
			child.hide()
	p_control.show()

func _ready():
	Fleet.focus_entered.connect(self.indicate_selected_button.bind(Fleet))
	Refit.focus_entered.connect(self.indicate_selected_button.bind(Refit))
	connect_buttons_lazy()
	#Inventory.focus_entered.connect($"../../..".indicate_selected_button(Inventory))
	#Map.focus_entered.connect($"../../..".indicate_selected_button(Map))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
