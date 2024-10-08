extends ShipSystem

class_name Stealth

func activate() -> void:
	#change to targeted_ship for stealth that is supposed to vary. just a proof of concept for now
	targeted_ship.sensor_profile = targeted_ship.sensor_profile * .05

func deactivate() -> void:
	#set to base stat value later on.
	targeted_ship.sensor_profile = targeted_ship.sensor_profile * 20
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
