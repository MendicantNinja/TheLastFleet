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

# Hide all GUI
func indicate_selected_button(p_control: Control) -> void:
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
	#Inventory.focus_entered.connect($"../../..".indicate_selected_button(Inventory))
	#Map.focus_entered.connect($"../../..".indicate_selected_button(Map))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
