extends TextureButton
class_name WeaponSlotDisplay

var ship_stats_weapon_slot: WeaponSlot
var ship_weapon_slot: WeaponSlot
var square_size: Vector2
var display_this: bool = false
@onready var WeaponSelectedRect: TextureRect = %WeaponSelectedRect
var root
# Called when the node enters the scene tree for the first time.


func _ready():
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	self.gui_input.connect(_on_input_event)
	WeaponSelectedRect.self_modulate = Color (1.5, 1.5, 0, 1.0 )
	pass # Replace with function body.

func _on_input_event(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		root.player_fleet.add_item(ship_weapon_slot.weapon)
		ship_weapon_slot.weapon = data.weapon_dictionary.get(data.weapon_enum.EMPTY)
		ship_stats_weapon_slot.weapon = data.weapon_dictionary.get(data.weapon_enum.EMPTY)
		print("The ship_stats weapon in refit_weapon is/is not equal to the one in player fleet ", ship_stats_weapon_slot == game_state.player_fleet.fleet_stats.ships[0].weapon_slots[0])
		root.update_weapon_list()
		
		
	
func _on_focus_entered() -> void:
	ship_weapon_slot.toggle_display_aim(true)
	%WeaponSelectedRect.visible = true
	root.display_weapon_list(self)
	pass

func _on_focus_exited() -> void:
	root.hide_weapon_list()
	ship_weapon_slot.toggle_display_aim(false)
	%WeaponSelectedRect.visible = false

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
