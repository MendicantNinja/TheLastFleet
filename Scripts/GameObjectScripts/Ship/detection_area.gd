extends Area2D

@onready var DetectionRadius: CollisionShape2D = $DetectionRadius
@onready var self_ship: Ship
# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect signals to detection logic
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

#func setup(radius: int) -> void:
	#DetectionRadius.shape.radius = radius
# Triggered when a ship enters the radius. Body == ship.gd
func _on_body_entered(body):
	if body != self_ship and body is Ship:
		if body.ships_detecting_me == 0:
			body.is_revealed = true
		body.ships_detecting_me += 1

# Triggered when a ship leaves the radius
func _on_body_exited(body):
	if  body != self_ship and body is Ship:
		body.ships_detecting_me -= 1
		if body.ships_detecting_me == 0:
			body.is_revealed = false
