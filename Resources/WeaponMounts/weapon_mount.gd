extends Resource
class_name WeaponMount
# ballistic 
# energy
# hybrid
# missile
# universal

# Misc properties. Do not export the weapon_mount_name, it is determined at runtime.
var weapon_mount_name: String
@export var weapon_mount_type: data.weapon_mount_type_enum = data.weapon_mount_type_enum.BALLISTIC
@export var weapon_mount_size: data.size_enum = data.size_enum.SMALL
@export var image: Texture2D = preload("res://Art/WeaponArt/weapon_mount.png")


@export var firing_arc: int = 360 # up to 360
@export var is_fixed: bool = false # no moving the turret allowed

# Override the get_property_list function
func _get_property_list() -> Array:
	var properties = []
	# Create a dictionary entry for weapon_mount_name
	var mount_name_property = {
		"name": "weapon_mount_name",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_NONE,
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY
	}
	# Add weapon_mount_name to the property list
	properties.append(mount_name_property)
	return properties

# Override the get method to calculate weapon_mount_name dynamically
func _get(property: StringName) -> Variant:
	if property == "weapon_mount_name":
	# Calculate weapon_mount_name dynamically based on the enum values
		return "%s %s" % [data.size_enum.keys()[weapon_mount_size].capitalize(), data.weapon_mount_type_enum.keys()[weapon_mount_type].capitalize()]
	return get(property)  # Return other properties normally



# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
