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

func add_item(item_to_add: Resource, number_of_items: int = 1) -> void:
	var item: ItemSlot
	if item_to_add is Weapon and item_to_add.item_enum != data.item_enum.EMPTY:
		item = ItemSlot.new(item_to_add.item_enum, number_of_items)
		fleet_stats.inventory.append(item)
	else:
		push_error("Not a valid item to add, please code the implementation")
	merge_weapons()

func remove_item_slot(item_index: int) -> void:
	fleet_stats.inventory.remove_at(item_index)

func remove_single_item(item_slot: ItemSlot) -> void:
	var index_to_remove: int
	item_slot.number_of_items -= 1
	if item_slot.number_of_items < 1:
		for i in fleet_stats.inventory.size():
			if fleet_stats.inventory[i] == item_slot:
				index_to_remove = i
		remove_item_slot(index_to_remove)
	if data.item_dictionary.get(item_slot.type_of_item) is Weapon:
		merge_weapons()
	
func move_item(to_index: int, from_index: int) -> void:
	if to_index < 0 or to_index >= fleet_stats.inventory.size() or from_index < 0 or from_index >= fleet_stats.inventory.size():
		push_error("Fleet->move_item() index out of bounds")
		return

	if to_index != from_index:
		var temp_item = fleet_stats.inventory[to_index]
		fleet_stats.inventory[to_index] = fleet_stats.inventory[from_index]
		fleet_stats.inventory[from_index] = temp_item

func sort_inventory() -> void:
	# Sort by type
	if fleet_stats.inventory and fleet_stats.inventory.size() > 1:
		fleet_stats.inventory.sort_custom(compare_items_by_type)
	merge_weapons()

# Merge Identical Weapon Stacks in the Inventory
func merge_weapons() -> void:
	# Step 1: Create a dictionary to store merged weapons
	var weapons_map: Dictionary = {}  # type_of_item enum = key, ItemSlot = value
	
	# Step 2: Collect weapons for merging
	var weapons_list: Array[ItemSlot] = []
	var weapons_to_remove: Array[int] = []

	# Iterate over the inventory and collect weapons to merge
	for i in range(fleet_stats.inventory.size()):
		var item_slot = fleet_stats.inventory[i]
		
		if item_slot.type_of_item != data.item_enum.EMPTY and data.item_dictionary.get(item_slot.type_of_item) is Weapon:
			weapons_list.append(item_slot)
			weapons_to_remove.append(i)  # Track indices to remove later

	# Step 3: Remove the weapons from the inventory (in reverse order)
	# Reverse iteration to avoid index shifting during removals
	for i in range(weapons_to_remove.size() - 1, -1, -1):
		fleet_stats.inventory.remove_at(weapons_to_remove[i])

	# Step 4: Merge weapons based on their type_of_item
	for item_slot in weapons_list:
		if item_slot.type_of_item in weapons_map:
			# If the weapon type already exists in the map, merge by adding the number_of_items
			weapons_map[item_slot.type_of_item].number_of_items += item_slot.number_of_items
		else:
			# If the weapon is new, just add it
			weapons_map[item_slot.type_of_item] = item_slot
	
	# Step 5: Add merged weapons back into the inventory
	for weapon_type in weapons_map:
		# Append the merged weapon stack back to the inventory
		fleet_stats.inventory.append(weapons_map[weapon_type])

	# Debugging output
	print("Merged weapons:")
	print("Inventory size after merging: ", fleet_stats.inventory.size())
	for item_slot in fleet_stats.inventory:
		print(item_slot.type_of_item, " ",  item_slot.number_of_items)

func compare_items_by_type(a: ItemSlot, b: ItemSlot) -> int:
	print("compare_items_by_type called")
	if a.type_of_item < b.type_of_item:
		return -1  # a comes before b
	elif a.type_of_item > b.type_of_item:
		return 1   # a comes after b
	return 0       # a and b are equal
