extends ItemList
var ships_to_deploy: Array[ShipStats] = []

func _ready():
	self.item_selected.connect(self.on_item_selected)



func setup_deployment_screen() -> void:
	# Add ships to the display and set the ship itself as item metadata.
	for ship in game_state.player_fleet.fleet_stats.ships:
		var index: int = add_item(str(ship.deployment_points), ship.ship_hull.ship_sprite, true)
		set_item_metadata(index, ship)
	print("Setup successful fleet size is")
	print(self.item_count)

func on_item_selected(item_index: int) -> void:
	var ship: ShipStats = get_item_metadata(item_index)
	ships_to_deploy.append(ship)
	set_item_selectable(item_index, false)




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
