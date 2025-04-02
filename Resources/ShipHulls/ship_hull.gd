extends Resource
class_name ShipHull
# This class contains the base stats of the ship before any mods are applied.

# Boolean checks
#@export var is_carrier: bool = false

# Core Ship Attributes
@export var ship_type_name: String = "" # Name of the ship (e.g, "Raptor"). Fighters are named after birds of prey.
@export_multiline var ship_description: String = ""
@export var ship_type: data.ship_type_enum # Specific type of the ship (e.g., RAPTOR)
@export var ship_size: data.ship_size_enum  # The size of ship (e.g., FIGHTER, FRIGATE, DESTROYER)
@export var ship_tech: data.tech_enum # The tech level or classification of the ship (E.G. HIGH-TECH, MEDIUM-TECH, LOW-TECH
@export var ship_packed_scene: PackedScene # I wonder if this will cause recursion issues?
# Ship Systems
@export var ship_system: data.ship_system_enum = data.ship_system_enum.NONE          # The special ability or system that the ship has (e.g., "Phase Cloak", "Burn Drive")
@export var weapon_mounts: Array[WeaponMount] = []               # Array of weapon mounts (e.g., types of hardpoints, turrets). Ends up ultimately being set by the packed scene?
@export var base_mods: Array = []                       # List of hullmods that come packaged with the base hull.

# Ship Dimensions
@export var ship_sprite: Texture2D = load("res://Art/ShipArt/fighter.png")        # Ship art
@export var ship_scaling = 1                  # Do you want to scale the ship art up or down?

# Weapon Systems and Mounts

#@export var ballistic_slots: int              # Number of ballistic weapon slots
#@export var energy_slots: int                 # Number of energy weapon slots
#@export var missile_slots: int                # Number of missile weapon slots
#@export var universal_slots: int              # Number of universal weapon slots

# Defensive Stats
@export var hull_integrity: int                    # Ship's total hit points (health)
@export var armor: int                        # Ship's armor rating (used for damage mitigation)

@export var shield_arc: int = 120 # Shield arc in degrees (converted to radians in shield_slot.gd). 360 is not full coverage, 375 is
@export var shield_efficiency: float          # How effective the shields are at blocking damage
@export var shield_upkeep: float              # Some variable that has to do with shields idk how
@export var flux: int                         # Total flux the ship can buildup before overloading
@export var flux_dissipation: int             # Rate at which flux is dissipated (flux/sec)

# Movement Stats
@export var top_speed: int                    # Base speed of the ship in combat
@export var acceleration: float               # How fast the ship accelerates
@export var deceleration: float               # How fast the ship slows down
@export var turn_rate: float                  # How fast the ship can rotate
@export var mass: float                       # Ship's mass (affects collision and inertia)

# Combat Readiness, Supplies, Fuel, Crew
@export var drive_field: int = 10
@export var deployment_points: float = 1.00           # How many deployment points the ship costs in combat
@export var base_cr: float = 65              # The base combat readiness of the ship
@export var cr_recovery_rate: float = 2           # Rate at which combat readiness is restored post-combat
@export var cr_deployment_cost: float         # Combat readiness cost for deploying in battle

@export var cargo_capacity: int               # Maximum cargo capacity of the ship
@export var supplies_per_month: float         # Supplies used per month for maintenance
@export var supplies_per_deployment: float    # Supplies used for combat deployment

@export var fuel_capacity: int                # Maximum fuel the ship can carry
@export var fuel_usage_per_lightyear: float   # Fuel used per lightyear of travel

@export var crew_capacity: int                # Maximum crew the ship can hold
@export var skeleton_crew: int                # Minimum crew needed to operate the ship
@export var fighter_bays: int = 0              # Number of fighter bays for carrier-type ships

# Miscellaneous Stats
@export var sensor_strength: int            # Strength of the ship's sensors
@export var sensor_profile: int            # How easily the ship is detected by sensors
@export var repair_rate: float                # How fast the ship can repair damage outside of combat
