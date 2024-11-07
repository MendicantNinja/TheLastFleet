extends TextureButton
class_name FleetShipIcon

@onready var index: int
var ship: ShipStats
@onready var ship_sprite: TextureButton = $ShipSprite
@onready var ship_label: Label = $ShipSprite/Label
@onready var ship_panel: Panel = $ShipSprite/ShipPanel

func _get_drag_data(position) -> FleetShipIcon:
	var dragged_ship: FleetShipIcon = self    # This is your custom method generating the drag data.
	set_drag_preview(self.duplicate()) # This is your custom method generating the preview of the drag data.
	return self

func _can_drop_data(at_position, data) -> bool:
	return true
	#if data == FleetShipIcon:
		#print("can drop data true called")
		#return true
	#else:
		#print("can drop data false called")
		#return false

func _drop_data(position, data) -> void:
		game_state.player_fleet.move_ship(data.index, self.index)
		get_node("../../..").update_fleet_list()
		#get_tree().current_scene.update_fleet_list()
	
func on_added_to_container() -> void:
	self.ship_sprite.self_modulate = settings.player_color
	self.ship_label.text = "%s Class" % ship.ship_hull.ship_type_name
	#settings.swizzle(ShipPanel)

func _ready():
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
