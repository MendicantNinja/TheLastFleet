extends CharacterBody2D
class_name Fleet

# Things that don't really vary with immediate player input in the galaxy map.
@export var max_thrust: int = 0
@export var ships: Array[ShipStats] = []

# Things that do vary with immediate player input in the galaxy map.
@export var thrust: int = 0


func add_ship(ship: ShipStats) -> void:
	pass

func remove_ship(ship_to_remove: int) -> void:
	pass

func move_ship(to_index: int, from_index: int) -> void:
	pass

func refit_ship(ship_to_refit: int) -> void:
	pass

func sell_ship(ship_to_sell: int) -> void:
	pass



# Called when the node enters the scene tree for the first time.
func _ready():
	position = Vector2(0, 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
