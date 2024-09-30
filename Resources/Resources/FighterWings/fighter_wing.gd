extends Resource
class_name FighterWing

@export var wing_name: String = "Winginton"
@export var fighter_type: ShipHull
@export var armament_points: int = 0
@export var number_of_fighters: int = 1
@export var replenishment_rate: int = 5 
#@export var wing_strength: int = 100 modify in combat, then reset on combat end?



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
