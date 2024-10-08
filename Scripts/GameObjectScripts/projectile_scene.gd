extends Area2D
class_name ProjectileScene

# Stats
@export var projectile: Projectile

# What happens when the projectile hits? Grab damage_per_shot from projectile.weapon and collided_object_instance for the enemy to calculate. Play a noise from projectile.noise.
func hit() -> void:
	if projectile == null or projectile.weapon == null:
		push_error("No weapon and/or projectile detected for projectile scene. res://Resources/Projectiles/projectile.gd ")
		return
	pass
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
