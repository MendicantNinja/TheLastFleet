extends Node2D
class_name WeaponSlot

# Nodes
@onready var weapon_mount_image: Sprite2D = $WeaponMountSprite 
@onready var weapon_image: Sprite2D = $WeaponMountSprite/WeaponSprite

# Important Stuff
#@export var assigned_ship: Ship
@export var weapon: Weapon:
	set(value):
		weapon = value
		if weapon_image != null:
			weapon_image.texture = value.image
		else:
			return
@export var weapon_mount: WeaponMount:
	set(value):
		weapon_mount = value
		if weapon_mount_image != null:
			weapon_mount_image.texture = value.image
		else:
			return

# Bools and toggles
@onready var ready_to_fire: bool = true # This is that little green bar in Starsector for missiles and burst weapons that reload. Not important yet.

# Called to spew forth a --> SINGLE <-- projectile scene from the given Weapon in the WeaponSlot. Firing speed is tied to delta in ship.gd.
func fire(ship_id: int) -> void:
	if weapon != data.weapon_dictionary.get(data.weapon_enum.EMPTY):
		#for i in weapon.burst_size: # <--- 1 by default. not important yet, but you can see how this can be used for burst functionality
			#weapon.create_projectile()
		var projectile: Area2D = weapon.create_projectile().instantiate()
		projectile.assign_stats(weapon, ship_id)
		projectile.global_position = global_position + Vector2(0, 0) # Should come out of the edge/front of the weapon.
		projectile.global_rotation = rotation
		get_tree().root.add_child(projectile)
		# FOR YELYMANE: Shoot the target! Impart velocity! Add random spread based on accuracy. Etc. 
		
# Only called by ship_stats.initialize() or on implicit new in the generic ship scene. Never again.
func _init(p_weapon_mount: WeaponMount = data.weapon_mount_dictionary.get(data.weapon_mount_enum.SMALL_BALLISTIC), p_weapon: Weapon = data.weapon_dictionary.get(data.weapon_enum.EMPTY)):
	weapon_mount = p_weapon_mount
	weapon = p_weapon

func _ready():
	weapon_mount_image.texture = weapon_mount.image
	weapon_image.texture = weapon.image
	set_weapon_size_and_color()

func set_weapon_size_and_color():
	weapon_mount_image.modulate = settings.player_color
	#weapon_image.self_modulate = settings.player_color
	match weapon_mount.weapon_mount_size:
		data.size_enum.SMALL:
			self.scale = Vector2(.2, .2)#/assigned_ship.scale # Important to scale weapon slots so that the size is constant.
		data.size_enum.MEDIUM:
			self.scale = Vector2(.4, .4)#/assigned_ship.scale
		data.size_enum.LARGE:
			self.scale = Vector2(.7, .7)#/assigned_ship.scale
		data.size_enum.SPINAL:
			self.scale = Vector2(1, 1)#/assigned_ship.scale
		_:
			print("Unknown weapon size.")
	
	
	#match weapon_mount.weapon_mount_type:
		#data.weapon_mount_type_enum.BALLISTIC:
			#weapon_mount_image.self_modulate = Color8(255, 100, 20, 255)
		#data.weapon_mount_type_enum.ENERGY:
			#weapon_mount_image.self_modulate = Color8(0, 212, 255, 255)
		#data.weapon_mount_type_enum.HYBRID:
			#weapon_mount_image.self_modulate = Color8(0, 255, 123, 255)
		#data.weapon_mount_type_enum.MISSILE:
			#weapon_mount_image.self_modulate = Color8(255, 51, 0, 255)
		#data.weapon_mount_type_enum.UNIVERSAL:
			#weapon_mount_image.self_modulate = Color8(255, 198, 184, 255)
		#_:
			#print("Unknown weapon type.")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
