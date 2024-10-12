extends Area2D
class_name Projectile

# Stats
var projectile_damage: int = 0 
var projectile_speed: float = 0
# Should be called when the projectile is created in weapon.gd.
func assign_stats(weapon: Weapon) -> void: 
	projectile_damage = weapon.damage_per_shot
	projectile_speed = weapon.projectile_speed

# What happens when the projectile hits? We have damage and the collided_object_instance for the enemy to calculate.
func hit() -> void:
	if projectile_damage == 0:
		push_error("No weapon detected for projectile scene. res://Scenes/CompositeGameObjects/Projectiles/RailgunProjectile.tscn")
		return
	#Yelymane's code here.
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
