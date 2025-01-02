extends Resource
class_name ShipStats

# This class contains the unique modified stats of a ship based on player modifications calculated on update.
# For all intents and purposes, ship_stats is what makes an individual, unique ship in a fleet for serialization.

# Called on ship.new() implicitly.
func _init(ship_type: data.ship_type_enum) -> void:
	ship_hull = data.ship_type_dictionary.get(ship_type)
	initialize()
	update()
	pass

func new_ship_name(p_ship_name: String = "Shippington") -> void:
	if p_ship_name == "Shippington":
		random_ship_name()
	else: 
		ship_name  = p_ship_name

func random_ship_name() -> String:
	return "LolSoRandom"

# Called once on creation. This function assigns certain variables like ship_system that don't need automatically updated ever again after initial assignment.
func initialize() -> void:
	new_ship_name()
	ship_system = data.ship_system_dictionary.get(ship_hull.ship_system)
	
	# Assign empty weapon slots based on the ship hulls mounts.
	weapon_slots.resize(ship_hull.weapon_mounts.size())
	for i in range(ship_hull.weapon_mounts.size()):
		weapon_slots[i] = WeaponSlot.new(ship_hull.weapon_mounts[i]) # New automatically assigns the weapon as empty here.

# Updates stats. Internal function not called outside of this script. Should be called with a co-function whenever there is potentially a stat change (a new hull mod).
func update() -> void:
	# Defensive Stats
	drive_field = ship_hull.drive_field + bonus_drive_field
	hull_integrity = ship_hull.hull_integrity + bonus_hull_integrity
	armor = ship_hull.armor + bonus_armor
	shield_efficiency = ship_hull.shield_efficiency + bonus_shield_efficiency
	flux = ship_hull.flux + bonus_flux
	flux_dissipation = ship_hull.flux_dissipation + bonus_flux_dissipation

	# Movement Stats
	top_speed = ship_hull.top_speed + bonus_top_speed
	acceleration = ship_hull.acceleration + bonus_acceleration
	deceleration = ship_hull.deceleration + bonus_deceleration
	turn_rate = ship_hull.turn_rate + bonus_turn_rate
	mass = ship_hull.mass + bonus_mass

	# Combat Readiness, Supplies, Fuel, Crew
	deployment_points = ship_hull.deployment_points + bonus_deployment_points
	base_cr = ship_hull.base_cr + bonus_base_cr
	cr_recovery_rate = ship_hull.cr_recovery_rate + bonus_cr_recovery_rate
	cr_deployment_cost = ship_hull.cr_deployment_cost + bonus_cr_deployment_cost
	cargo_capacity = ship_hull.cargo_capacity + bonus_cargo_capacity
	supplies_per_month = ship_hull.supplies_per_month + bonus_supplies_per_month
	supplies_per_deployment = ship_hull.supplies_per_deployment + bonus_supplies_per_deployment
	fuel_capacity = ship_hull.fuel_capacity + bonus_fuel_capacity
	fuel_usage_per_lightyear = ship_hull.fuel_usage_per_lightyear + bonus_fuel_usage_per_lightyear
	crew_capacity = ship_hull.crew_capacity + bonus_crew_capacity
	skeleton_crew = ship_hull.skeleton_crew + bonus_skeleton_crew
	fighter_bays = ship_hull.fighter_bays + bonus_fighter_bays

	# Miscellaneous Stats
	sensor_strength = ship_hull.sensor_strength + bonus_sensor_strength
	sensor_profile = ship_hull.sensor_profile + bonus_sensor_profile
	repair_rate = ship_hull.repair_rate + bonus_repair_rate
	pass

# Ship Mod Functionality
func add_mod(p_ship_mod: ShipMod) -> void:
	# Add the mod to the ship_mods array
	ship_mods.append(p_ship_mod)
	update_mods()
	
func remove_mod(ship_index: int) -> void:
	ship_mods.remove_at(ship_index)
	update_mods()
	
func update_mods() -> void:
	# Reset all bonuses before recalculating
	bonus_range = 0
	
	bonus_hull_integrity = 0
	bonus_armor = 0
	bonus_shield_efficiency = 0.0
	bonus_flux = 0
	bonus_flux_dissipation = 0

	bonus_top_speed = 0
	bonus_acceleration = 0.0
	bonus_deceleration = 0.0
	bonus_turn_rate = 0.0
	bonus_mass = 0.0

	bonus_deployment_points = 0
	bonus_base_cr = 0.0
	bonus_cr_recovery_rate = 0.0
	bonus_cr_deployment_cost = 0.0
	bonus_cargo_capacity = 0
	bonus_supplies_per_month = 0.0
	bonus_supplies_per_deployment = 0.0
	bonus_fuel_capacity = 0
	bonus_fuel_usage_per_lightyear = 0.0
	bonus_crew_capacity = 0
	bonus_skeleton_crew = 0
	bonus_fighter_bays = 0

	bonus_sensor_strength = 0
	bonus_sensor_profile = 0
	bonus_repair_rate = 0.0

	# Loop through each ShipMod and apply the bonuses and multipliers
	for mod in ship_mods:
		
	# Not found in ship_hull.gd. Applies to weapons.
	#bonus_range = += int(ship_hull.hull_integrity * mod.hull_integrity_multiplier) + mod.bonus_hull_integrity
	# Defensive Stats
		bonus_hull_integrity += int(ship_hull.hull_integrity * mod.hull_integrity_multiplier) + mod.bonus_hull_integrity
		bonus_armor += int(ship_hull.armor * mod.armor_multiplier) + mod.bonus_armor
		bonus_shield_efficiency += ship_hull.shield_efficiency * mod.shield_efficiency_multiplier + mod.bonus_shield_efficiency
		bonus_flux += int(ship_hull.flux * mod.flux_multiplier) + mod.bonus_flux
		bonus_flux_dissipation += int(ship_hull.flux_dissipation * mod.flux_dissipation_multiplier) + mod.bonus_flux_dissipation

		# Movement Stats
		bonus_top_speed += int(ship_hull.top_speed * mod.top_speed_multiplier) + mod.bonus_top_speed
		bonus_acceleration += ship_hull.acceleration * mod.acceleration_multiplier + mod.bonus_acceleration
		bonus_deceleration += ship_hull.deceleration * mod.deceleration_multiplier + mod.bonus_deceleration
		bonus_turn_rate += ship_hull.turn_rate * mod.turn_rate_multiplier + mod.bonus_turn_rate
		bonus_mass += ship_hull.mass * mod.mass_multiplier + mod.bonus_mass

		# Combat Readiness, Supplies, Fuel, Crew
		bonus_drive_field += mod.bonus_drive_field
		bonus_deployment_points += snapped(ship_hull.deployment_points * mod.deployment_points_multiplier + mod.bonus_deployment_points, 0.01)
		bonus_base_cr += ship_hull.base_cr * mod.base_cr_multiplier + mod.bonus_base_cr
		bonus_cr_recovery_rate += ship_hull.cr_recovery_rate * mod.cr_recovery_rate_multiplier + mod.bonus_cr_recovery_rate
		bonus_cr_deployment_cost += ship_hull.cr_deployment_cost * mod.cr_deployment_cost_multiplier + mod.bonus_cr_deployment_cost
		bonus_cargo_capacity += int(ship_hull.cargo_capacity * mod.cargo_capacity_multiplier) + mod.bonus_cargo_capacity
		bonus_supplies_per_month += ship_hull.supplies_per_month * mod.supplies_per_month_multiplier + mod.bonus_supplies_per_month
		bonus_supplies_per_deployment += ship_hull.supplies_per_deployment * mod.supplies_per_deployment_multiplier + mod.bonus_supplies_per_deployment
		bonus_fuel_capacity += int(ship_hull.fuel_capacity * mod.fuel_capacity_multiplier) + mod.bonus_fuel_capacity
		bonus_fuel_usage_per_lightyear += ship_hull.fuel_usage_per_lightyear * mod.fuel_usage_per_lightyear_multiplier + mod.bonus_fuel_usage_per_lightyear
		bonus_crew_capacity += int(ship_hull.crew_capacity * mod.crew_capacity_multiplier) + mod.bonus_crew_capacity
		bonus_skeleton_crew += int(ship_hull.skeleton_crew * mod.skeleton_crew_multiplier) + mod.bonus_skeleton_crew
		bonus_fighter_bays += int(ship_hull.fighter_bays * mod.fighter_bays_multiplier) + mod.bonus_fighter_bays

		# Miscellaneous Stats
		bonus_sensor_strength += ship_hull.sensor_strength * mod.sensor_strength_multiplier + mod.bonus_sensor_strength
		bonus_sensor_profile += ship_hull.sensor_profile * mod.sensor_profile_multiplier + mod.bonus_sensor_profile
		bonus_repair_rate += ship_hull.repair_rate * mod.repair_rate_multiplier + mod.bonus_repair_rate
	update()

# Ship Weapon Mounting and Addition.
func add_weapon(weapon_to_add: Weapon, weapon_slot_index: int) -> void:
	if weapon_slot_index > ship_hull.weapon_mounts.size()-1 or weapon_slot_index < 0:
		push_error("Cannot add weapon to this weapon slot, the weapon slot does not exist or the index is incorrect.")
		return
	weapon_slots[weapon_slot_index].weapon = weapon_to_add

func remove_weapon(weapon_slot_index: int) -> void:
	if weapon_slot_index > ship_hull.weapon_mounts.size()-1 or weapon_slot_index < 0:
		push_error("Cannot remove weapon from this weapon slot, the weapon slot does not exist or the index is incorrect.")
		return
	weapon_slots[weapon_slot_index].weapon = data.weapon_dictionary.get(data.weapon_enum.EMPTY)
	
# Ship Systems
@export var ship_name: String = "Shippington" # The name of this specific ship in the fleet.
@export var ship_hull: ShipHull 
@export var ship_system: ShipSystem           # The special ability or system that the ship has (e.g., "Phase Cloak", "Burn Drive")
@export_storage var weapon_slots: Array[WeaponSlot] = []               # Array of weapons+mounts equipped in the weapon mounts? (e.g., types and positions of hardpoints, turrets)
@export_storage var weapon_systems: Array[WeaponSystem] = [ # Indexes 0-7
	WeaponSystem.new(), WeaponSystem.new(), WeaponSystem.new(), WeaponSystem.new(),
	WeaponSystem.new(), WeaponSystem.new(), WeaponSystem.new(), WeaponSystem.new()
]
@export var ship_mods: Array[ShipMod] = []                       # List of hullmods including base_mods
@export var fighters: Array[FighterWing] = []

# Weapon Systems and Mounts

# Defensive Stats
@export var hull_integrity: int                    # Ship's total hit points (health)
@export var armor: int                        # Ship's armor rating (used for damage mitigation)

@export var shield_efficiency: float          # How effective the shields are at blocking damage
@export var flux: int                         # Total flux the ship can buildup before overloading
@export var flux_dissipation: int             # Rate at which flux is dissipated (flux/sec)

# Movement Stats
@export var top_speed: int                    # Max speed of the ship in combat
@export var acceleration: float               # How fast the ship accelerates
@export var deceleration: float               # How fast the ship slows down
@export var turn_rate: float                  # How fast the ship can rotate
@export var mass: float                       # Ship's mass (affects collision and inertia)

# Combat Readiness, Supplies, Fuel, Crew
@export var drive_field: int
@export var deployment_points: float           # How many deployment points the ship costs in combat
@export var base_cr: float = 65              # The base combat readiness of the ship
@export var cr_recovery_rate: float = 2       # Rate at which combat readiness is restored post-combat
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
@export var sensor_profile: int             # How easily the ship is detected by sensors
@export var repair_rate: float                # How fast the ship can repair damage outside of combat

# Ship Mod Stats and Bonus Calculations
#NOTE: When modifying a variable or adding a new one. Ensure that ship_hull.gd, ship_stats.gd (and all the other instances of that variable), and ship_mod.gd are updated or reflect this change.

#Ship-Mod unique stats not found in ship_hull
@export var bonus_range: int = 0

@export var bonus_hull_integrity: int = 0
@export var bonus_armor: int = 0
@export var bonus_shield_efficiency: float = 0.0
@export var bonus_flux: int = 0
@export var bonus_flux_dissipation: int = 0

@export var bonus_top_speed: int = 0
@export var bonus_acceleration: float = 0.0
@export var bonus_deceleration: float = 0.0
@export var bonus_turn_rate: float = 0.0
@export var bonus_mass: float = 0.0

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
