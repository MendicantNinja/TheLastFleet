extends Resource
class_name FleetStats

# Things that don't really vary with immediate player input in the galaxy map.
@export var is_player: bool
@export var faction: data.faction_enum

@export var max_drive_field: int = 0

@export var ships: Array[ShipStats] = []
@export_storage var inventory: Array[ItemSlot] = []

# Things that do vary with immediate player input in the galaxy map.
@export var position: Vector2 = Vector2(0,0)
@export var thrust: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#position = Vector2(0, 0)
