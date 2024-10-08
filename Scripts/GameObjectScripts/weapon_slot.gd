extends Node2D
class_name WeaponSlot

@export var assigned_ship: Ship
@export var weapon: Weapon
@export var weapon_mount: WeaponMount
# Used for serializing equipped weapons properly and knowing which weapon slot is which.
@onready var weapon_mount_image: Sprite2D = $WeaponMountSprite 
@onready var weapon_image: Sprite2D = $WeaponMountSprite/WeaponSprite
# Called when the node enters the scene tree for the first time.
func _ready():
	weapon_mount_image.texture = weapon_mount.image
	if weapon_image.texture != null:
		weapon_image.texture = weapon.image
	set_weapon_size_and_color()
	pass
	
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
