extends Resource

class_name ShipSystem
# Change type to "ship" later. Since we'll need to increase current speed and acceleration with burn drives. 
var targeted_ship: ShipStats
@export var flux_cost: int = 0
@export var flux_dissiptation_allowed: bool = true
@export var duration: int = 0

# These are overriden. 
func activate() -> void:
	pass

func deactivate() -> void:
	pass
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
