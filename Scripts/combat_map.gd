extends Node2D

func _ready() -> void:
	var friendly_group: Array = get_tree().get_nodes_in_group("friendly")
	for friendly_ship in friendly_group:
		connect_ship_signals(friendly_ship)
	pass

func _physics_process(delta) -> void:
	pass

func _unhandled_input(event) -> void:
	pass

# Connect any signals at the start of the scene to ensure that all friendly and enemy ships
# are more than capable of signaling to each other changes to specific local scene information.
# Currently it only handles signals for friendly ships but it would take little to no effort to
# expand this for both. Ideally, we only use this to connect signals that are required for BOTH
# enemies and friendlies. 
func connect_ship_signals(friendly_ship: Ship) -> void:
	var enemy_group: Array = get_tree().get_nodes_in_group("enemy")
	for ship in enemy_group:
		ship.ship_targeted.connect(friendly_ship._on_ship_targeted)
