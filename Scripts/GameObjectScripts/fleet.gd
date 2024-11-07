extends Node2D
class_name Fleet
var fleet_stats: FleetStats = FleetStats.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func add_ship(ship: ShipStats) -> void:
	fleet_stats.ships.append(ship)
	update_fleet()

func remove_ship(ship_index: int) -> void:
	fleet_stats.ships.remove_at(ship_index)
	update_fleet()

func move_ship(to_index: int, from_index: int) -> void:
	if to_index < 0 or to_index >= fleet_stats.ships.size() or from_index < 0 or from_index >= fleet_stats.ships.size():
		push_error("Fleet->move_ship() index out of bounds")
		return

	if to_index != from_index:
		var temp_ship = fleet_stats.ships[to_index]
		fleet_stats.ships[to_index] = fleet_stats.ships[from_index]
		fleet_stats.ships[from_index] = temp_ship

func add_item(item: ItemSlot) -> void:
	fleet_stats.inventory.append(item)

func remove_item(item_index: int) -> void:
	fleet_stats.inventory.remove_at(item_index)

func move_item(to_index: int, from_index: int) -> void:
	if to_index < 0 or to_index >= fleet_stats.inventory.size() or from_index < 0 or from_index >= fleet_stats.inventory.size():
		push_error("Fleet->move_item() index out of bounds")
		return

	if to_index != from_index:
		var temp_item = fleet_stats.inventory[to_index]
		fleet_stats.inventory[to_index] = fleet_stats.inventory[from_index]
		fleet_stats.inventory[from_index] = temp_item

func update_fleet() -> void:
	var max_drive_variable: int = 0
	for ship in fleet_stats.ships:
		if ship.drive_field > max_drive_variable:
			fleet_stats.max_drive_field = ship.drive_field
		else:
			continue

func refit_ship(ship_to_refit: int) -> void:
	pass

func sell_ship(ship_to_sell: int) -> void:
	pass
