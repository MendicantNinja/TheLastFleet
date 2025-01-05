extends HBoxContainer


# Called when the node enters the scene tree for the first time.

func initialize(weapon: Weapon) -> void:
	%AutofireLabel.text = weapon.name

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
