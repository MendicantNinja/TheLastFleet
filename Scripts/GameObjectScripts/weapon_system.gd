# Used for storing autofire data in ship stats. Doesn't actually use the weapons array so much.
extends Object
class_name WeaponSystem

var auto_fire_start: bool = false
var auto_fire: bool = false

var weapons: Array[WeaponSlot] = []

func add_weapon(weapon: WeaponSlot) -> void:
	if not weapons.has(weapon):
		weapons.append(weapon)
	print(weapons)

func remove_weapon(weapon: WeaponSlot) -> void:
	if weapons.has(weapon):
		weapons.erase(weapon)
	print(weapons)
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
