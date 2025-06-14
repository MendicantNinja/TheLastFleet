extends Panel
class_name WeaponSlotDisplay

var ship_stats_weapon_slot: WeaponSlot # weapon slot in the ship_stats data
var ship_weapon_slot: WeaponSlot # weapon slot in the packed scene
var draw_rectangle: bool = false
var rectangle_color: Color = Color(0.765, 0.404, 0.129, 255)
@onready var WeaponSelectedRect: Control = %WeaponSelectedRect
var root
# Called when the node enters the scene tree for the first time.


func _ready():
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	self.gui_input.connect(_on_input_event)
	pass # Replace with function body.

func _on_input_event(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		root.player_fleet.add_item(ship_weapon_slot.weapon)
		ship_weapon_slot.weapon = data.weapon_dictionary.get(data.weapon_enum.EMPTY)
		ship_stats_weapon_slot.weapon = data.weapon_dictionary.get(data.weapon_enum.EMPTY)
		#print("The ship_stats weapon at position 0 in refit_weapon is/is not equal to the one in player fleet ", ship_stats_weapon_slot == game_state.player_fleet.fleet_stats.ships[0].weapon_slots[0])
		root.update_weapon_list()
		
	
func _on_focus_entered() -> void:
	ship_weapon_slot.toggle_display_aim(true)
	%WeaponSelectedRect.visible = true
	root.display_weapon_list(self)
	draw_rectangle = true
	queue_redraw()
	pass

func _on_focus_exited() -> void:
	root.hide_weapon_list()
	ship_weapon_slot.toggle_display_aim(false)
	%WeaponSelectedRect.visible = false
	draw_rectangle = false
	queue_redraw()

func _on_mouse_entered() -> void:
	ship_weapon_slot.toggle_display_aim(true)
	pass
	
func _on_mouse_exited() -> void:
	if has_focus() == true:
		ship_weapon_slot.toggle_display_aim(true)
	else:
		ship_weapon_slot.toggle_display_aim(false)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
