extends Control
@onready var RefitPanel = %RefitPanel
@onready var RefitList = %RefitList
@onready var ShipView = %ShipView
# Called when the node enters the scene tree for the first time.

@onready var player_fleet: Fleet = game_state.player_fleet
@onready var player_fleet_stats: FleetStats = player_fleet.fleet_stats




# Called when the node enters the scene tree for the first time.
func _ready():
	settings.swizzle(RefitPanel, settings.gui_color)
	update_refit_list()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


# Create the ships in the list and the ability to scroll down
func update_refit_list() -> void:
	var scene_path: String = "res://Scenes/GUIScenes/OtherGUIScenes/FleetGUIShipIcon.tscn"
	var fleet_gui_icon_scene = load(scene_path)
	# Populate the GUI with a list of ships in the fleet from 0 to i. 
	var children = RefitList.get_children()
	for child in children:
		child.free()
	for i in range(player_fleet_stats.ships.size()):
		var ship_icon: FleetShipIcon = fleet_gui_icon_scene.instantiate()
		var ship_stat: ShipStats = player_fleet_stats.ships[i]
		ship_icon.ship = ship_stat
		RefitList.add_child(ship_icon)
		ship_icon.owner = self
		ship_icon.ship_sprite.texture_normal = ship_icon.ship.ship_hull.ship_sprite
		ship_icon.ship_sprite.custom_minimum_size = Vector2(%ScrollContainer.size.x, %ScrollContainer.size.x) * .9
		ship_icon.custom_minimum_size = ship_icon.ship_sprite.custom_minimum_size
		ship_icon.pivot_offset = ship_icon.custom_minimum_size/2 - position
		ship_icon.on_added_to_container()
		ship_icon.index = i
	
# When a ship is selected in the panel. Set shipview to the new ship.
func view_ship(ship: Ship) -> void:
	ShipView.add_child(ship)
	ship.position = ShipView.size/2
	pass
