extends Resource
class_name WeaponMount
# ballistic 
# energy
# hybrid
# missile
# universal

@export var weapon_mount_type: data.weapon_mount_type_enum = data.weapon_mount_type_enum.BALLISTIC
@export var weapon_mount_size: data.size_enum = data.size_enum.SMALL
@export var firing_arc: int = 45 # up to 360, 0 is north/upwards.
@export var is_fixed: bool = false 



# Automatically calculated with a getter. Do not export.
var weapon_mount_name: String:
	get:
		return "%s %s" % [data.size_enum.keys()[weapon_mount_size].capitalize(), data.weapon_mount_type_enum.keys()[weapon_mount_type].capitalize()]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
