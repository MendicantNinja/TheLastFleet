extends Resource
class_name ShipMod

@export var mod_name: String = "Moddington"
@export var armament_points: int = 0

# Ship-Mod unique bonuses and multipliers.
@export var range_multiplier: float = 1.0
@export var bonus_range: int = 0

# Defensive Stats Multipliers
@export var hull_integrity_multiplier: float = 1.0
@export var armor_multiplier: float = 1.0
@export var shield_efficiency_multiplier: float = 1.0
@export var flux_multiplier: float = 1.0
@export var flux_dissipation_multiplier: float = 1.0

# Movement Stats Multipliers
@export var top_speed_multiplier: float = 1.0
@export var acceleration_multiplier: float = 1.0
@export var deceleration_multiplier: float = 1.0
@export var turn_rate_multiplier: float = 1.0
@export var mass_multiplier: float = 1.0

# Combat Readiness, Supplies, Fuel, Crew Multipliers
@export var deployment_points_multiplier: float = 1.0
@export var base_cr_multiplier: float = 1.0
@export var cr_recovery_rate_multiplier: float = 1.0
@export var cr_deployment_cost_multiplier: float = 1.0
@export var cargo_capacity_multiplier: float = 1.0
@export var supplies_per_month_multiplier: float = 1.0
@export var supplies_per_deployment_multiplier: float = 1.0
@export var fuel_capacity_multiplier: float = 1.0
@export var fuel_usage_per_lightyear_multiplier: float = 1.0
@export var crew_capacity_multiplier: float = 1.0
@export var skeleton_crew_multiplier: float = 1.0
@export var fighter_bays_multiplier: float = 1.0

# Miscellaneous Stats Multipliers
@export var sensor_strength_multiplier: float = 1.0
@export var sensor_profile_multiplier: float = 1.0
@export var repair_rate_multiplier: float = 1.0

# Defense
@export var bonus_hull_integrity: int = 0
@export var bonus_armor: int = 0
@export var bonus_shield_efficiency: float = 0.0
@export var bonus_flux: int = 0
@export var bonus_flux_dissipation: int = 0

# Mobility
@export var bonus_top_speed: int = 0
@export var bonus_acceleration: float = 0.0
@export var bonus_deceleration: float = 0.0
@export var bonus_turn_rate: float = 0.0
@export var bonus_mass: float = 0.0

# Logistics
@export var bonus_drive_field: int = 0
@export var bonus_deployment_points: float = 0.0
@export var bonus_base_cr: float = 0.0
@export var bonus_cr_recovery_rate: float = 0.0
@export var bonus_cr_deployment_cost: float = 0.0
@export var bonus_cargo_capacity: int = 0
@export var bonus_supplies_per_month: float = 0.0
@export var bonus_supplies_per_deployment: float = 0.0
@export var bonus_fuel_capacity: int = 0
@export var bonus_fuel_usage_per_lightyear: float = 0.0
@export var bonus_crew_capacity: int = 0
@export var bonus_skeleton_crew: int = 0
@export var bonus_fighter_bays: int = 0

@export var bonus_sensor_strength: int = 0
@export var bonus_sensor_profile: int = 0
@export var bonus_repair_rate: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
