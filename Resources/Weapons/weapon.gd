extends Resource
class_name Weapon

# Misc Stats
@export var weapon_name: String = "Ratsmacker"
@export var weapon_size: data.size_enum = data.size_enum.SMALL
@export var image: Texture2D = preload("res://Art/WeaponArt/weapon.png")
@export var projectile_scene: PackedScene
@export var firing_sound: Resource

# Damage-related stats
@export var damage_type: data.weapon_damage_enum = data.weapon_damage_enum.KINETIC                # Type of damage (kinetic, high-explosive, energy, fragmentation)
@export var armament_points: int = 0
@export var damage_per_shot: int = 0                   # The amount of damage dealt per shot
@export var fire_rate: float = 0.0                     # Rate of fire (shots per second)
@export var burst_size: int = 0                        # Number of shots in a burst, for burst-type weapons
@export var burst_delay: float = 0.0                   # Delay between bursts for burst-fire weapons

# Range and Accuracy
@export var range: float = 1000                         # Maximum range of the weapon
@export var beam: bool = false                         # Whether the weapon is a continuous beam
@export var accuracy: float = 1.0                      # Accuracy of the weapon (0.0 = low, 1.0 = perfect)
@export var spread: float = 0.0                        # Spread of the weapon’s shots (applies to some projectile weapons)
@export var turn_rate: float = 10.0                     # How fast the weapon can rotate to track targets

# Flux-related stats
@export var flux_per_shot: int = 0                     # Amount of flux generated per shot

# Projectile and effects
@export var projectile_speed: float = 10.0              # Speed of projectiles fired by the weapon
@export var projectile_lifetime: float = 100.0           # Lifetime of projectiles before they disappear

# Ammunition-related stats
#later @export var ammo_capacity: int = -1                    # Maximum ammo capacity (-1 means infinite ammo)
#later @export var ammo_regen_rate: float = 1.0               # Ammo regeneration rate (for weapons with regenerating ammo)
#later @export var ammo_per_shot: int = 1                     # Ammo consumed per shot

# Weapon attributes
#later @export var tracking: bool = false                     # Whether the weapon tracks its target
#later @export var charge_time: float = 0.0                   # Time taken to charge the weapon before firing
#later @export var cooldown_time: float = 0.0                 # Cooldown time after firing

# Miscellaneous



#@export var impact_effect: String = ""                 # Visual or sound effect when the weapon hits a target

# Dynamically calculated with a getter stats
@export var dps: int = 0                               # Damage per second. Calculate with a getter.
@export var flux_per_second: int = 0                   # Flux generated per second of fire