extends Resource
class_name FleetStats

# Things that don't really vary with immediate player input in the galaxy map.
@export var is_player: bool
@export var faction: data.faction_enum

@export var max_drive_field: int = 0

@export var ships: Array[ShipStats] = []
@export_storage var inventory: Array[ItemSlot] = []

var star_id: int = -1;
var sector_id: int;

var supplies: int:
	get:
		return 1

var fuel: int:
	get:
		return 1
# Things that do vary with immediate player input in the galaxy map.
@export var position: Vector2 = Vector2(0,0)
@export var thrust: int = 0
func _init():
	if inventory.is_empty():
		inventory.append(ItemSlot.new(data.item_enum.RAILGUN, 8))
# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
