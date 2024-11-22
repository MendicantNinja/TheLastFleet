extends Control
@onready var RefitPanel = %RefitPanel
@onready var RefitList = %RefitList
@onready var ShipView = %ShipView
@onready var InventoryScrollContainer = %InventoryScrollContainer
@onready var InventoryList = %InventoryList

# Called when the node enters the scene tree for the first time.

@onready var player_fleet: Fleet = game_state.player_fleet
@onready var player_fleet_stats: FleetStats = player_fleet.fleet_stats

var displayed_ship: Ship
var ship_weapons_display: Array[TextureButton]


# Called when the node enters the scene tree for the first time.
func _ready():
	settings.swizzle(RefitPanel, settings.gui_color)
	update_refit_list()
	update_weapon_list()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Hide the weapon list if left clicked in an empty area AKA no GUI element handled it
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_weapon_list()

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

# Update weapons display when installing or uninstalling weapons, or entering the scene
func update_weapon_list() -> void:
	var scene_path: String = "res://Scenes/GUIScenes/OtherGUIScenes/WeaponItemRefit.tscn"
	var weapon_item_count_scene = load(scene_path)
	var weapon_list: Array[ItemSlot]
	
	# Clear the display
	for child in InventoryList.get_children():
		child.queue_free()
	
	# Sort weapons. Find weapons in the inventory
	for item_slot in player_fleet_stats.inventory:
		if data.item_dictionary.get(item_slot.type_of_item) is Weapon:
			weapon_list.append(item_slot)
	
	# Display the weapon list GUI
	for weapon_count in weapon_list:
		var weapon_item: TextureButton = weapon_item_count_scene.instantiate()
		InventoryList.add_child(weapon_item)
		weapon_item.WeaponName.text = str(data.item_enum.keys()[weapon_count.type_of_item]).capitalize()
		weapon_item.WeaponInfo.text = "Range " + str(data.item_dictionary.get(weapon_count.type_of_item).range)
		weapon_item.WeaponCount.text = str(weapon_count.number_of_items) + " in inventory"
		weapon_item.OrdinancePointCount.text = str(data.item_dictionary.get(weapon_count.type_of_item).armament_points)
		weapon_item.item_slot = weapon_count
# When a ship is selected in the panel. Set Shipview's child to the new ship.

func display_weapon_list(this_weapon_display: TextureButton) -> void:
	InventoryScrollContainer.visible = true
	InventoryScrollContainer.global_position.y = this_weapon_display.global_position.y - this_weapon_display.size.y
	InventoryScrollContainer.global_position.x = this_weapon_display.global_position.x - InventoryList.size.x - 50

func hide_weapon_list() -> void:
	InventoryScrollContainer.visible = false

func view_ship(ship: Ship) -> void:
	for child in ShipView.get_children():
		child.queue_free()
	ship_weapons_display.clear()
	displayed_ship = ship
	ShipView.add_child(displayed_ship)
	displayed_ship.position = ShipView.size/2
	
	# Display and Hide Appropriate GUI
	for weapon_slot in displayed_ship.all_weapons:
		var weapon_slot_selection: WeaponSlotDisplay = load("res://Scenes/GUIScenes/OtherGUIScenes/WeaponSlotDisplay.tscn").instantiate()
		#var weapon_slot_selection: WeaponSlotDisplay = WeaponSlotDisplay.new()
		weapon_slot_selection.weapon_slot = weapon_slot
		ShipView.add_child(weapon_slot_selection)
		weapon_slot_selection.scale = weapon_slot.weapon_mount_image.scale
		weapon_slot_selection.square_size = weapon_slot.weapon_mount_image.get_rect().size
		weapon_slot_selection.global_position = weapon_slot.weapon_mount_image.global_position
		#ABSOLUTE BULLSHIT HACK: ARBITRARY SCALING OF 1.55 AND MODULATING WEAPON_SLOT_DISPLAY TO TRANSPARENCY. MAY NOT WORK FOR LARGER MOUNTS!!
		weapon_slot_selection.pivot_offset = -(weapon_slot_selection.size * weapon_slot_selection.scale)  / 1.55
		weapon_slot_selection.root = self

	ship.CenterCombatHUD.visible = false
