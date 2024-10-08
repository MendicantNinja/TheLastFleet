extends Resource
class_name Projectile

# Stats
@export var weapon: Weapon 
#@export var hit_noise: Resource
# What happens when the projectile hits? Grab damage_per_shot from weapon and collided_object_instance for the enemy to calculate. Play a noise.
func hit() -> void:
	if weapon == null:
		push_error("No weapon detected for projectile. res://Resources/Projectiles/projectile.gd ")
		return
	pass


func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
