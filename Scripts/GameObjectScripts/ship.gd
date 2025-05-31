extends RigidBody2D
class_name Ship

@onready var ShipNavigationAgent = $ShipNavigationAgent
@onready var ShipSprite = $ShipSprite
@onready var AvoidanceArea = $AvoidanceArea
@onready var AvoidanceShape = $AvoidanceArea/AvoidanceShape
@onready var SeparationArea = $SeparationArea
@onready var SeparationShape = $SeparationArea/SeparationShape
@onready var ForceDebug = $ForceDebug

# Camera references needed for GUI scaling and some other things, signaling up is difficult. Processing overhead is terrible. Memory is insanely cheap for 2D games. Would have to involve passing the ships as a parameter and would be called repeatedly in process.
@onready var CombatCamera = null
@onready var TacticalCamera = null
@onready var ManualControlLoadingBar

@onready var ManualControlHUD = null
@onready var CenterCombatHUD: Control = $CenterCombatHUD
@onready var ConstantSizedGUI = CenterCombatHUD.ConstantSizedGUI
@onready var SoftFluxIndicator = CenterCombatHUD.SoftFluxIndicator
@onready var HardFluxIndicator = CenterCombatHUD.HardFluxIndicator
@onready var HullIntegrityIndicator = CenterCombatHUD.HullIntegrityIndicator
@onready var FluxPip = CenterCombatHUD.FluxPip
@onready var ManualControlIndicator = CenterCombatHUD.ManualControlIndicator
@onready var ShipTargetIcon = CenterCombatHUD.ShipTargetIcon
@onready var ShipNameDebugText = CenterCombatHUD.ShipNameDebugText

var tactical_map_icon: TacticalMapIcon
var TacticalMapLayer: CanvasLayer
var TacticalDataDrawing: Node2D 

@onready var CombatBehaviorTree = $CombatBehaviorTreeRedux
@onready var CombatTimer = $CombatTimer
@onready var OverloadTimer = $OverloadTimer
@onready var RetreatTimer = $RetreatTimer

# Temporary variables
# Should group weapon slots in the near future instead of this, 
# even though call_group() broke in 4.3 stable.
@onready var ShieldSlot = $ShieldSlot
@onready var ShieldShape
@onready var DetectionArea = $DetectionArea
var shield_rid: RID

var ShipWrapper
var SteerData

# ship stats
var ship_stats: ShipStats
var speed: float = 0.0
var hull_integrity: float = 0.0:
	set(value):
		ShipWrapper.SetHullIntegrity(value)
		hull_integrity = value

var armor: float = 0.0:
	set(value):
		ShipWrapper.SetArmor(value)
		armor = value

var shield_radius: float = 0.0

var total_flux: float = 0.0:
	set(value):
		ShipWrapper.SetTotalFlux(value)
		total_flux = value # Flux Capacity

var soft_flux: float = 0.0:
	set(value):
		ShipWrapper.SetSoftFlux(value)
		soft_flux = value # Soft Flux Capacity

var hard_flux: float = 0.0:
	set(value):
		ShipWrapper.SetHardFlux(value)
		hard_flux = value # Hard Flux Capacity

var shield_upkeep: float = 0.0
var overload_time: float = 5.0
var passive_flux_dissipation: float = 0.0
var vf_coe: float = 3.0
var vent_flux_dissipation: float = 0.0
var shield_toggle: bool = false:
	set(value):
		ShipWrapper.SetShieldFlag(value)
		shield_toggle = value

var flux_overload: bool = false:
	set(value):
		ShipWrapper.SetFluxOverload(value)
		flux_overload = value

var targeted: bool = false
var average_weapon_range: float = 0.0:
	set(value):
		ShipWrapper.SetAvgWeaponRange(value)
		average_weapon_range = value

var is_revealed: bool:
	set(value):
		if settings.debug_mode == true:
			return
		if value == true:
			visible = value
			tactical_map_icon.disabled = value
			tactical_map_icon.visible = value
		elif value == false:
			visible = value
			tactical_map_icon.disabled = value
			tactical_map_icon.visible = value

var ships_detecting_me: int = 0 # Increment this counter for enemies when entering a detection body. Decrement when exiting. See detection_area.gd in the packed scene.

var is_friendly: bool = false:
	set(value):
		ShipWrapper.SetIsFriendly(value)
		is_friendly = value

var manual_control: bool = false:
	set(value):
		if value == false:
			manual_control = false
			ManualControlIndicator.visible = false
		elif value == true:
			manual_control = true
			ManualControlIndicator.visible = true

var camera_feed: bool = false

# Used for targeting and weapons.
var weapon_systems: Array[WeaponSystem] = [
	WeaponSystem.new(), WeaponSystem.new(), WeaponSystem.new(), WeaponSystem.new(),
	WeaponSystem.new(), WeaponSystem.new(), WeaponSystem.new(), WeaponSystem.new()
]
var selected_weapon_system: WeaponSystem = weapon_systems[0]
var all_weapons: Array[WeaponSlot] = []
var aim_direction: Vector2 = Vector2.ZERO
var mouse_hover: bool = false

# camera goodies
var manual_camera_freelook: bool = false
var zoom_in_limit: Vector2 = Vector2(1.2, 1.2)
var zoom_out_limit: Vector2 = Vector2(0.6, 0.6)
var zoom_value: Vector2 = Vector2.ONE

# group/unit stuff
var group_name: StringName = &"":
	set(value):
		ShipWrapper.SetGroupName(value)
		group_name = value

var group_leader: bool = false:
	set(value):
		if value == true:
			print("%s made leader of %s" % [name, group_name])
		else:
			print("%s is no longer group leader" % [name])
		ShipWrapper.SetGroupLeader(value)
		group_leader = value

var posture: globals.Strategy = globals.Strategy.NEUTRAL:
	set(value):
		ShipWrapper.SetPosture(value)
		posture = value

var match_speed: float = 0.0

# Used for combat AI / behavior tree / influence map
var combat_goal: int = 0:
	set(value):
		ShipWrapper.SetCombatGoal(value)
		combat_goal = value

var occupancy_radius: int = 0

var approx_influence: float = 0.0:
	set(value):
		approx_influence = value

var registry_cluster: Array = []:
	set(value):
		ShipWrapper.SetRegistryCluster(value)
		registry_cluster = value

var imap_cell: Vector2i = Vector2i.ZERO:
	set(value):
		ShipWrapper.SetImapCell(value)
		imap_cell = value

var registry_cell: Vector2i = Vector2i.ZERO:
	set(value):
		ShipWrapper.SetRegistryCell(value)
		registry_cell = value

var registry_neighborhood: Array = []:
	set(value):
		ShipWrapper.SetRegistryNeighborhood(value)
		registry_neighborhood = value

var heur_velocity: Vector2 = Vector2.ZERO
var combat_time: float = 5.0
var retreat_time: float = 10.0
var target_unit: RigidBody2D = null:
	set(value):
		target_unit = value

var targeted_units: Array[RigidBody2D] = []:
	set(value):
		ShipWrapper.SetTargetedUnits(value, SteerData)
		targeted_units = value

var neighbor_units: Array = []:
	set(value):
		ShipWrapper.SetNeighborUnits(value)
		neighbor_units = value

var separation_neighbors: Array[RigidBody2D] = []:
	set(value):
		ShipWrapper.SetSeparationNeighbors(value)
		separation_neighbors = value

var nearby_enemy_groups: Array = []
var idle_neighbors: Array = []
var neighbor_groups: Array = []
var available_neighbor_groups: Array = []
var nearby_attackers: Array = []
var incoming_projectiles: Array = []
var targeted_by: Array[RigidBody2D] = []:
	set(value):
		var update_targeted_by: Array[RigidBody2D] = []
		for attacker in value:
			if attacker == null:
				continue
			if attacker is RigidBody2D:
				update_targeted_by.append(attacker)
		
		ShipWrapper.SetTargetedBy(update_targeted_by)
		targeted_by = update_targeted_by

var target_in_range: bool = false:
	set(value):
		if value == false and target_unit != null:
			print("%s out of range of target %s and searching for other targets" % [name, target_unit.name])
		ShipWrapper.SetTargetInRange(value, SteerData)
		target_in_range = value

var goal_flag: bool = false:
	set(value):
		ShipWrapper.SetGoalFlag(value)
		goal_flag = value

var brake_flag: bool = false:
	set(value):
		#ShipWrapper.SetBrakeFlag(value)
		brake_flag = value

var retreat_flag: bool = false:
	set(value):
		if value == true:
			print(name, " is retreating")
		elif retreat_flag == true and value == false:
			print(name, " is no longer retreating")
		tactical_map_icon.toggle_retreat_animation(value)
		ShipWrapper.SetRetreatFlag(value)
		retreat_flag = value

var fallback_flag: bool = false:
	set(value):
		ShipWrapper.SetFallbackFlag(value)
		fallback_flag = value

var combat_flag: bool = false:
	set(value):
		ShipWrapper.SetCombatFlag(value)
		if value == true:
			CombatTimer.start()
		combat_flag = value

var vent_flux_flag: bool = false:
	set(value):
		ShipWrapper.SetVentFluxFlag(value)
		vent_flux_flag = value

var deploy_flag: bool = false:
	set(value):
		ShipWrapper.SetDeployFlag(value)
		deploy_flag = value

var match_velocity_flag: bool = false:
	set(value):
		ShipWrapper.SetMatchVelocityFlag(match_velocity_flag)
		match_velocity_flag = value

var steer_debug: bool = true

var separation_force: Vector2 = Vector2.ZERO:
	set(value):
		ForceDebug.separation_force = value
		separation_force = value

var avoidance_force: Vector2 = Vector2.ZERO:
	set(value):
		ForceDebug.avoidance_force = value
		avoidance_force = value

var cohesion_force: Vector2 = Vector2.ZERO:
	set(value):
		ForceDebug.cohesion_force = value
		cohesion_force = value

var goal_force: Vector2 = Vector2.ZERO:
	set(value):
		ForceDebug.goal_force = value
		goal_force = value

#var adj_template_maps: Dictionary = {}

# Used for navigation and movement
var sensor_strength: int 
var time: float = 0.0
var zero_flux_bonus: float = 0.0
var time_coefficient: float = 0.1
var rotate_angle: float = 0.0
var move_direction: Vector2 = Vector2.ZERO:
	set(value):
		move_direction = value

var acceleration: Vector2 = Vector2.ZERO:
	set(value):
		acceleration = value

var target_position: Vector2 = Vector2.ZERO:
	set(value):
		if is_friendly == true:
			move_order_updated.emit(value)
		SteerData.SetTargetPosition(value)
		target_position = value

var threat_radius: int = 0:
	set(value):
		SteerData.SetThreatRadius(value * imap_manager.DefaultCellSize)
		threat_radius = value

var avoid_radius_sq: float = 0:
	set(value):
		SteerData.SetAvoidRadius(value)
		avoid_radius_sq = value

var sq_separation_radius: float = 0:
	set(value):
		SteerData.SetSqSeparationRadius(value)
		sq_separation_radius = value

var ship_select: bool = false:
	# Ship Select is for individual ships when they're the only ships
	set(value):
		if value == true: 
			ship_select = value
		elif value == false:
			ship_select = value
		#print("ship select called", ship_select)
		ship_selected.emit()

var collision_flag: bool = false
var ai_debug: bool = false

# Custom signals.
signal alt_select()
signal camera_removed()
signal switch_to_manual()
signal request_manual_camera()
signal ship_selected()
signal destroyed()
signal update_agent_influence()
signal update_registry_cell()
signal ship_deployed()
signal move_order_updated(value)

# Want to call a custom overriden _init when instantiating a packed scene? You're not allowed :(, so call this function after instantiating a ship but before ready()ing it in the node tree.
func initialize(p_ship_stats: ShipStats = ShipStats.new(data.ship_type_enum.TEST)) -> void:
	ship_stats = p_ship_stats

# Any adjustments before deploying the ship to the combat space. Called during/by FleetDeployment.
func deploy_ship() -> void:
	#print("deploy ship called")
	# Needed to know the zoom level for GUI scaling. Only works in CombatArena, not refit.
	
	if get_tree().current_scene.name == "CombatArena":
		# Deployed ships can't find references to other nodes in the scene since they are added at runtime. So set the paths up here as needed.
		#Is also convenient for ship refitting.
		TacticalDataDrawing = get_tree().get_root().find_child("TacticalDataDrawing", true, false)
		TacticalMapLayer = get_tree().get_root().find_child("TacticalMapLayer", true, false)
		CombatCamera = get_tree().get_root().find_child("CombatCamera", true, false)
		TacticalCamera = get_tree().get_root().find_child("TacticalMapCamera", true, false)
		ManualControlHUD =  get_tree().get_root().find_child("ManualControlHUD", true, false)
		ManualControlLoadingBar =  get_tree().get_root().find_child("ManualControlLoadingBar", true, false)
	if is_friendly == true:
		#print("deploy_ship called")
		settings.swizzle(ConstantSizedGUI, settings.gui_color, false)
		settings.swizzle($ShipLivery, settings.player_color)
		ManualControlIndicator.self_modulate = settings.player_color 
		DetectionArea.DetectionRadius.shape.radius  = sensor_strength
	elif is_friendly == false:
		# Non-identical to is_friendly == true Later in development. Swap these rectangle pictures with something else. (Starsector uses diamonds for enemies).
		settings.swizzle(ConstantSizedGUI, settings.enemy_color, false)
		settings.swizzle($ShipLivery, settings.enemy_color)

func _ready() -> void:
	ShipWrapper = load("res://Scripts/GameObjectScripts/ShipWrapper.cs").new()
	add_child(ShipWrapper)
	ShipWrapper.name = &"ShipWrapper"
	SteerData = load("res://Scripts/GameObjectScripts/CombatAI/BehaviorTreeC#/BehaviorPool/Steering/SteerData.cs").new()
	add_child(SteerData)
	SteerData.name = &"SteerData"
	
	if ship_stats == null:
		ship_stats = ShipStats.new(data.ship_type_enum.CHALLENGER)
	var ship_hull = ship_stats.ship_hull
	add_to_group(&"agent")
	if collision_layer == 1:
		is_friendly = true
		name = &"Player " + ship_hull.ship_type_name
		add_to_group(&"friendly")
		rotation -= PI/2
	else:
		name = &"Enemy " + ship_hull.ship_type_name
		add_to_group(&"enemy")
		is_friendly = false
		rotation += PI/2
	
	if steer_debug == true:
		ForceDebug.force_debug = true
		ShipNameDebugText.add_text(name)
	
	ShipSprite.z_index = 0
	$ShipLivery.z_index = 1
	registry_cell = -Vector2i.ONE
	speed = ship_stats.top_speed + ship_stats.bonus_top_speed
	ShipNavigationAgent.max_speed = speed
	
	OverloadTimer.wait_time = overload_time
	CombatTimer.wait_time = combat_time
	RetreatTimer.wait_time = retreat_time
	RetreatTimer.timeout.connect(_on_RetreatTimer_timeout)
	
	var texture: Texture2D = ship_hull.ship_sprite
	var texture_size: Vector2 = texture.get_size()
	var new_radius: float = sqrt(texture_size.x**2 + texture_size.y**2) / 2
	ShipNavigationAgent.radius = new_radius
	
	var dissipation_coe: float = 12
	passive_flux_dissipation = (ship_stats.flux_dissipation + ship_stats.bonus_flux_dissipation)
	passive_flux_dissipation /= dissipation_coe
	vent_flux_dissipation = (ship_stats.flux_dissipation + ship_stats.bonus_flux_dissipation) * vf_coe / dissipation_coe
	
	ShipSprite.texture = ship_hull.ship_sprite
	hull_integrity = ship_hull.hull_integrity
	armor = ship_hull.armor
	shield_radius = ShipNavigationAgent.radius
	shield_upkeep = ship_hull.shield_upkeep / 60.0
	ShieldShape = ShieldSlot.ShieldShape
	ShieldSlot.shield_parameters(ship_stats.shield_arc, collision_layer, get_rid().get_id(), self)
	ShieldSlot.shield_hit.connect(_on_Shield_Hit)
	shield_rid = ShieldSlot.get_rid()
	total_flux = ship_stats.flux
	zero_flux_bonus = floor(speed / 3)
	var target_unit_offset: Vector2 = Vector2(-shield_radius, shield_radius)
	var manual_control_offset: Vector2 = Vector2(shield_radius, shield_radius) * -1.2
	ShipTargetIcon.position = target_unit_offset
	ManualControlIndicator.position = manual_control_offset
	ManualControlIndicator.visible = false
	ShipTargetIcon.visible = false
	HullIntegrityIndicator.max_value = ship_stats.hull_integrity
	HullIntegrityIndicator.value = hull_integrity
	
	sensor_strength = ship_stats.sensor_strength
	DetectionArea.self_ship = self
	# TEMPORARY FIX FOR MENDI'S AMUSEMENTON
	#ShipSprite.modulate = self_modulate
	
	# Assigns weapon slots based on what's in the ship scene.
	for child in get_children():
		if child is WeaponSlot:
			all_weapons.append(child)
			child.detection_parameters(collision_mask, is_friendly, get_rid(), shield_rid)
			child.weapon_slot_fired.connect(_on_Weapon_Slot_Fired)
			child.target_in_range.connect(_on_target_in_range)

	# Assign weapon system groups and weapons based on ship_stats.
	for i in range(all_weapons.size()):
		all_weapons[i].set_weapon_slot(ship_stats.weapon_slots[i])
		if all_weapons[i].weapon != data.weapon_dictionary.get(data.weapon_enum.EMPTY):
			weapon_systems[all_weapons[i].weapon_system_group].add_weapon(all_weapons[i])
	# Turn on and off autofire as the refit system and ship stats demand.
	for i in ship_stats.weapon_systems.size():
		if ship_stats.weapon_systems[i].auto_fire_start == true:
			weapon_systems[i].auto_fire_start = true
	
	var weapon_ranges: Array = []
	for weapon_slot in all_weapons:
		average_weapon_range += weapon_slot.weapon.range
		weapon_ranges.append(weapon_slot.weapon.range)
	
	average_weapon_range /= weapon_ranges.size()
	
	#var occupancy_template: ImapTemplate
	#var threat_template: ImapTemplate
	
	var longest_range: float = weapon_ranges.max()
	occupancy_radius = (ship_stats.acceleration + ship_stats.bonus_acceleration + zero_flux_bonus) / 60
	occupancy_radius += 1
	threat_radius = (longest_range / imap_manager.DefaultCellSize) + 1
	SteerData.SetOccupancyRadius(occupancy_radius * imap_manager.DefaultCellSize)
	ShipWrapper.InitializeAgentImaps(self, imap_manager, occupancy_radius, threat_radius, collision_layer)
	var separation_shape: Shape2D = CircleShape2D.new()
	var separation_radius: float = new_radius * 5.0
	separation_shape.radius = separation_radius
	sq_separation_radius = separation_radius * separation_radius
	SeparationShape.shape = separation_shape
	SeparationArea.collision_mask = collision_mask
	SeparationArea.body_entered.connect(_on_SeparationShape_body_entered)
	SeparationArea.body_exited.connect(_on_SeparationShape_body_exited)
	
	var avoidance_shape: Shape2D = CircleShape2D.new()
	var avoid_radius: float = ship_stats.top_speed * (occupancy_radius + 2)
	avoid_radius_sq = avoid_radius * avoid_radius
	avoidance_shape.radius = avoid_radius
	AvoidanceShape.shape = avoidance_shape
	AvoidanceArea.collision_mask = collision_mask
	AvoidanceArea.body_entered.connect(_on_AvoidanceShape_body_entered)
	AvoidanceArea.body_exited.connect(_on_AvoidanceShape_body_exited)
	AvoidanceArea.area_entered.connect(_on_AvoidanceShape_area_entered)
	AvoidanceArea.area_exited.connect(_on_AvoidanceShape_area_exited)
	OverloadTimer.timeout.connect(_on_OverloadTimer_timeout)
	
	if is_friendly == true and ai_debug == true:
		set_combat_ai(true)
	elif is_friendly == false and ai_debug == true:
		for weapon: WeaponSlot in all_weapons:
			weapon.ai_debug = true
	else:
		set_combat_ai(true)
	deploy_ship()
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)

func tutorial_setup() -> void:
	if is_friendly == false:
		for weapon: WeaponSlot in all_weapons:
			weapon.ai_debug = true

func process_damage(projectile: Projectile) -> void:
	## Regular damage processing

	combat_flag = true
	CombatTimer.start()
	# Beam damage logic is a little bit different than normal projectiles
	if projectile.is_beam == true:
		#print("projectile beam process damage was called")
		# Armor should be done differently with beams. Probably. Playtesting needed.
		if projectile.is_continuous == false:
			var beam_projectile_divisor: float = projectile.beam_duration * 20.0
			var inverse_divisor: float = 1.0 / beam_projectile_divisor
			var beam_projectile_damage: int = int(projectile.damage * inverse_divisor)
			#print(beam_projectile_damage)
			var armor_damage_reduction: float = projectile.damage / (projectile.damage + armor)
			armor -= armor_damage_reduction
			#armor_damage_reduction = 1
			var hull_damage: float = armor_damage_reduction * beam_projectile_damage
			#print(hull_damage)
			hull_integrity -= hull_damage
			HullIntegrityIndicator.value = hull_integrity
		else:
			#var beam_projectile_divisor: int = 1 / .05
			var beam_projectile_damage: int = int(projectile.damage * .05 )
			#print(beam_projectile_damage)
			var armor_damage_reduction: float = projectile.damage / (projectile.damage + armor)
			armor -= armor_damage_reduction
			#armor_damage_reduction = 1
			var hull_damage: float = armor_damage_reduction * beam_projectile_damage
			#print(hull_damage)
			hull_integrity -= hull_damage
			HullIntegrityIndicator.value = hull_integrity
		
		
	elif projectile.is_beam == false:
		var armor_damage_reduction: float = projectile.damage / (projectile.damage + armor)
		armor -= armor_damage_reduction
		
		var hull_damage: float = armor_damage_reduction * projectile.damage
		hull_integrity -= hull_damage
		HullIntegrityIndicator.value = hull_integrity
	
	if hull_integrity <= 0.0:
		destroy_ship()
	if projectile.damage_type == data.weapon_damage_enum.KINETIC:
		globals.play_audio_pitched(load("res://Sounds/Combat/ProjectileHitSounds/kinetic_hit.wav"), projectile.global_position)

func destroy_ship() -> void:
	if manual_control == true:
		toggle_manual_control()
	destroyed.emit()
	
	remove_from_group(&"agent")
	if is_friendly == true:
		remove_from_group(&"friendly")
	elif is_friendly == false:
		remove_from_group(&"enemy")
	
	remove_from_group(group_name)
	if group_leader == true:
		globals.reset_group_leader(self)
	for weapon in all_weapons:
		if weapon.current_beam != null:
			weapon.stop_continuous_beam()
	var visited_group: Array = []
	for attacker in targeted_by:
		if attacker == null or attacker.is_queued_for_deletion():
			continue
		if attacker.group_name not in visited_group:
			var update_targets: Array[RigidBody2D] = attacker.targeted_units
			update_targets.erase(self)
			get_tree().call_group(attacker.group_name, "set_targets", update_targets)
			visited_group.append(attacker.group_name)
		attacker.target_unit = null
		attacker.SteerData.SetTargetUnit(null)
		attacker.ShipWrapper.SetTargetUnit(null)
	
	TacticalDataDrawing.setup()
	ShipTargetIcon.visible = false
	if retreat_flag == true and hull_integrity > 0.0:
		RetreatTimer.start()
	else:
		queue_free()

func set_shields(value: bool) -> void:
		shield_toggle = value
		ShieldSlot.toggle_shields(value)

func _on_Weapon_Slot_Fired(flux_cost) -> void:
	soft_flux += flux_cost
	combat_flag = true
	CombatTimer.start()
	update_flux_indicators()

func _on_Shield_Hit(damage: float, damage_type: int) -> void:
	hard_flux += damage * ship_stats.shield_efficiency
	combat_flag = true
	CombatTimer.start()
	update_flux_indicators()

func update_flux_indicators() -> void:
	var current_flux: float = ceil(soft_flux + hard_flux)
	if current_flux >= total_flux:
		flux_overload = true
		OverloadTimer.start()
		
		var flux_diff: float = current_flux - total_flux
		if hard_flux > soft_flux:
			hard_flux -= flux_diff
		else:
			soft_flux -= flux_diff
		
		for weapon in all_weapons:
			weapon.flux_overload = flux_overload
		set_shields(false)
	
	var flux_rate: float = 100 / total_flux # Returns a factor multiplier of the total flux that can be used to get a percentage. e.g 100/2000 = .05. 
	HardFluxIndicator.value = floor(flux_rate * hard_flux)
	SoftFluxIndicator.value = floor(flux_rate * soft_flux)
	SoftFluxIndicator.position.x = HardFluxIndicator.value
	FluxPip.position.x = HardFluxIndicator.value - 2

# Units/Groups

func group_remove(n_group_name: StringName) -> void:
	if group_leader == true and n_group_name == group_name:
		group_leader = false
	if n_group_name == group_name:
		group_name = &""
	print("%s removed from %s" % [name, n_group_name])
	remove_from_group(n_group_name)

func group_add(n_group_name: StringName) -> void:
	for weapon_slot in all_weapons:
		if weapon_slot.auto_fire:
			continue
		weapon_slot.set_auto_aim(true)
		weapon_slot.set_auto_fire(true)
	print("%s added to %s" % [name, n_group_name])
	group_name = n_group_name
	add_to_group(group_name)

func set_group_leader(value: bool) -> void:
	group_leader = value

func set_posture(value: globals.Strategy) -> void:
	posture = value

# Temporary workaround for now, not exactly great but whatever
func weigh_composite_influence(neighborhood_density: Dictionary) -> void:
	ShipWrapper.WeighCompositeInfluence(neighborhood_density)
	for cluster in neighborhood_density:
		if registry_cell in cluster:
			var lol = name
			var weight = 1 / neighborhood_density[cluster]
			registry_cluster = cluster
	#
	#var composite_influence: Imap = template_maps[imap_manager.MapType.INFLUENCE_MAP]
	#for m in range(0, composite_influence.height):
		#for n in range(0, composite_influence.width):
			#weigh_influence.map_grid[m][n] = composite_influence.map_grid[m][n] * abs(weight)
	#imap_manager.weighted_imap.add_map(weigh_influence, imap_cell.x, imap_cell.y, 1.0)

#ooooo ooooo      ooo ooooooooo.   ooooo     ooo ooooooooooooo 
#`888' `888b.     `8' `888   `Y88. `888'     `8' 8'   888   `8 
 #888   8 `88b.    8   888   .d88'  888       8       888      
 #888   8   `88b.  8   888ooo88P'   888       8       888      
 #888   8     `88b.8   888          888       8       888      
 #888   8       `888   888          `88.    .8'       888      
#o888o o8o        `8  o888o           `YbodP'        o888o    

# Any generic input event.
func _input(event: InputEvent) -> void:
	if TacticalMapLayer == null or TacticalMapLayer.visible or TacticalDataDrawing.camera_feed_active:
		return
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("m2") and manual_control and flux_overload == false:
			if shield_toggle == true:
				set_shields(false)
			else:
				set_shields(true)
		if event.is_action_released("select"):
				stop_firing_beams(selected_weapon_system.weapons)
		elif Input.is_action_just_pressed("zoom in") and manual_control and zoom_value < zoom_in_limit:
			zoom_value += Vector2(0.01, 0.01)
		elif Input.is_action_just_pressed("zoom out") and manual_control and zoom_value > zoom_out_limit:
			zoom_value -= Vector2(0.01, 0.01)
	elif event is InputEventKey:
		pass
		#if is_friendly:
			#elif (event.keycode == KEY_C and event.pressed) and manual_control:
				#toggle_auto_aim(all_weapons)
			#elif (event.keycode == KEY_V and event.pressed) and manual_control:
				#toggle_auto_fire(all_weapons)
		if not is_friendly: # for non-player/enemy ships
			if (event.keycode == KEY_R and event.pressed) and not mouse_hover:
				targeted = false
				ShipTargetIcon.visible = false
				_on_mouse_exited()
			elif (event.keycode == KEY_R and event.pressed) and mouse_hover:
				emit_signal("ship_targeted", get_rid())
				targeted = true
				ShipTargetIcon.visible = true

func toggle_ship_select() -> void:
	if is_friendly and not ship_select:
			ship_select = true # select ship
	elif is_friendly and ship_select:
			ship_select = false # deselect ship

func _on_mouse_entered() -> void:
	if TacticalMapLayer.visible:
		return
	mouse_hover = true
	if manual_control == false:
		for weapon_slot in all_weapons:
			weapon_slot.toggle_display_aim(mouse_hover)

func _on_mouse_exited() -> void:
	if TacticalMapLayer.visible:
		return
	mouse_hover = false
	if targeted or manual_control:
		return
	for weapon_slot in all_weapons:
		weapon_slot.toggle_display_aim(mouse_hover)

func highlight_selection(select_value: bool = false) -> void:
	#print("%s is highlighted? %s" % [name, select_value])
	tactical_map_icon.highlight_selection(select_value)
	get_viewport().set_input_as_handled()

func toggle_manual_control() -> void:
	# NOTE: If there are issues with combat AI not being flipped back on when leaving manual control. Uncomment this.
	# It should be fine given set_combat_ai() called later on in this method toggles the root.
	#if ship_select == false:
		#manual_control = false
		#CombatBehaviorTree.ToggleRoot(true)
		#return
	
	if manual_control == false:
		ManualControlLoadingBar.visible = true
		ManualControlLoadingBar.value = 0
		ManualControlLoadingBar.create_tween().tween_property(ManualControlLoadingBar, "value", 100, 1.5)
		await get_tree().create_timer(1.5).timeout  # delay in seconds
		ManualControlLoadingBar.visible = false
		manual_control = true
		ship_select = false
		ManualControlHUD.set_ship(self)
		ManualControlHUD.toggle_visible()
		CombatCamera.position_smoothing_enabled = false
		CombatCamera.global_position = self.global_position
		set_combat_ai(false)
		for weapon_system in self.weapon_systems:
			weapon_system.set_autofire(true)
			#if weapon_system.auto_fire_start == true:
				#toggle_auto_aim(weapon_system.weapons)
				#toggle_auto_fire(weapon_system.weapons)
		_on_mouse_exited()
	
	elif manual_control == true:
		retreat_flag = false
		fallback_flag = false
		match_velocity_flag = false
		manual_control = false
		set_combat_ai(true)
		ship_select = false
		for weapon_system in self.weapon_systems:
			weapon_system.set_autofire(true)
		ManualControlHUD.set_ship(null)
		_on_mouse_exited()
	
	toggle_manual_aim(all_weapons, manual_control)
	
	if manual_control == true and group_leader:
		set_group_leader(false)
	if manual_control == true and is_in_group(group_name):
		remove_from_group(group_name)
		group_name = &""
	if manual_control == true and ShipNavigationAgent.is_navigation_finished() == false:
		ShipNavigationAgent.set_target_position(position)
	
	
	#if manual_control == true:
		 # Bring up the ManualControlHUD CanvasLayer
		#switch_to_manual.emit() # Calls to Tactical Map to swap Camera and give a ship
		#request_manual_camera.emit() # Calls to combat map to switch the current/prev selected unit.

func toggle_manual_camera_freelook(toggle_status: bool) -> void:
	manual_camera_freelook = toggle_status

#oooooo   oooooo     oooo oooooooooooo       .o.       ooooooooo.     .oooooo.   ooooo      ooo  .oooooo..o 
 #`888.    `888.     .8'  `888'     `8      .888.      `888   `Y88.  d8P'  `Y8b  `888b.     `8' d8P'    `Y8 
  #`888.   .8888.   .8'    888             .8"888.      888   .d88' 888      888  8 `88b.    8  Y88bo.      
   #`888  .8'`888. .8'     888oooo8       .8' `888.     888ooo88P'  888      888  8   `88b.  8   `"Y8888o.  
	#`888.8'  `888.8'      888    "      .88ooo8888.    888         888      888  8     `88b.8       `"Y88b 
	 #`888'    `888'       888       o  .8'     `888.   888         `88b    d88'  8       `888  oo     .d8P 
	  #`8'      `8'       o888ooooood8 o88o     o8888o o888o         `Y8bood8P'  o8o        `8  8""88888P'  

func set_target_for_weapons(target) -> void:
	if target is not RigidBody2D:
		target = null
	for weapon in all_weapons:
		weapon.set_primary_target(target)

func fire_weapon_system(weapon_system: Array[WeaponSlot]) -> void:
	if vent_flux_flag == true or flux_overload == true:
		return
	
	for weapon_slot in weapon_system:
		fire_weapon_slot(weapon_slot)

func fire_weapon_slot(weapon_slot: WeaponSlot) -> void:
	if vent_flux_flag == true or flux_overload == true:
		return
	
	var ship_id = get_rid().get_id()
	if (total_flux - (hard_flux + soft_flux)) < weapon_slot.weapon.flux_per_shot:
		return 
	weapon_slot.fire(ship_id)

func toggle_manual_aim(weapon_system: Array[WeaponSlot], manual_aim_value: bool) -> void:
	if vent_flux_flag == true or flux_overload == true:
		return
	
	for weapon_slot in weapon_system:
		weapon_slot.set_manual_aim(manual_aim_value)
		weapon_slot.toggle_display_aim(manual_aim_value)

func toggle_auto_aim(weapon_system: Array[WeaponSlot]) -> void:
	if vent_flux_flag == true or flux_overload == true:
		return
	
	for weapon_slot in weapon_system:
		weapon_slot.toggle_auto_aim()

func toggle_auto_fire(weapon_system: Array[WeaponSlot]) -> void:
	if vent_flux_flag == true or flux_overload == true:
		return
	
	for weapon_slot in weapon_system:
		weapon_slot.toggle_auto_fire()

func stop_firing_beams(weapon_system: Array[WeaponSlot]) -> void:
	for weapon_slot in weapon_system:
		if weapon_slot.weapon.is_continuous == true:
			weapon_slot.stop_continuous_beam()
	pass

func set_navigation_position(to_position: Vector2) -> void:
	if targeted_units.is_empty() == false:
		get_tree().call_group(group_name, &"set_targets", [])
	target_position = to_position
	if group_leader == true:
		ShipNavigationAgent.set_target_position(to_position)
	get_viewport().set_input_as_handled()

@warning_ignore("narrowing_conversion")
func _physics_process(delta: float) -> void:
	if NavigationServer2D.map_get_iteration_id(ShipNavigationAgent.get_navigation_map()) == 0:
		return
	
	# Calculating flux dissipation in multiple places throughout the code is prone to disaster. Put any additions or subtractions in here.
	if Engine.get_physics_frames() % 5 == 0 and flux_overload == false:
		var flux_to_dissipate: float
		if shield_toggle == true:
			soft_flux += shield_upkeep
		
		# Dissipate soft_flux only if there is some to dissipate.
		if vent_flux_flag == false and (soft_flux > 0.0 or hard_flux > 0.0):
			flux_to_dissipate = passive_flux_dissipation
		if vent_flux_flag == true and (soft_flux > 0.0 or hard_flux > 0.0):
			flux_to_dissipate = vent_flux_dissipation
		
		if vent_flux_flag == true and shield_toggle == true:
			set_shields(false)
		
		if soft_flux > flux_to_dissipate: 
			#print("dissipating soft_flux", soft_flux)
			soft_flux -= flux_to_dissipate
		# Dissipate hardflux and soft flux if you have some soft flux, but some flux dissipation that dips into hardflux.
		elif soft_flux < flux_to_dissipate and soft_flux > 0.0:
			#print("potentially dissipating both flux types", hard_flux, soft_flux)
			var flux_to_carry_over: float = flux_to_dissipate - soft_flux # (10 dissipation - 3 soft flux = 7 left_over)
			hard_flux -= flux_to_carry_over
			soft_flux = 0.0
		# Dissipate hardflux if our layer of soft_flux is gone and hard_flux is greater than zero
		elif hard_flux > flux_to_dissipate:
			#print("dissipating hard_flux ", hard_flux)
			hard_flux -= flux_to_dissipate
		elif hard_flux <= flux_to_dissipate and hard_flux > 0.0:
			hard_flux = 0.0
		
		if hard_flux < 0.0:
			hard_flux = 0.0
		if soft_flux < 0.0:
			soft_flux = 0.0
		var current_flux: float = hard_flux + soft_flux
		if floor(current_flux) == 0.0 and vent_flux_flag == true:
			soft_flux = 0.0
			hard_flux = 0.0
			vent_flux_flag = false
			for weapon in all_weapons:
				weapon.flux_overload = false
		
		update_flux_indicators()
	
	if target_unit == null and target_in_range == true:
		_on_target_in_range(false)
	
	var current_imap_cell: Vector2i = Vector2i(global_position.y / imap_manager.DefaultCellSize, global_position.x / imap_manager.DefaultCellSize)
	if Engine.get_physics_frames() % 60 == 0 and current_imap_cell != imap_cell:
		var center_cell_position: Vector2i = Vector2i(current_imap_cell.y * imap_manager.DefaultCellSize, current_imap_cell.x * imap_manager.DefaultCellSize);
		center_cell_position.x += imap_manager.DefaultCellSize / 2.0;
		center_cell_position.y += imap_manager.DefaultCellSize / 2.0;
		var dist_to: float = center_cell_position.distance_to(global_position)
		if dist_to > imap_manager.DefaultCellSize * 0.45:
			update_agent_influence.emit()
			imap_cell = current_imap_cell
	
	var current_registry_cell: Vector2i = Vector2i(global_position.y / imap_manager.MaxCellSize, global_position.x / imap_manager.MaxCellSize)
	if Engine.get_physics_frames() % 60 == 0 and registry_cell != current_registry_cell:
		var center_cell_position: Vector2 = Vector2(current_registry_cell.y, current_registry_cell.x) * imap_manager.MaxCellSize
		center_cell_position.x += imap_manager.MaxCellSize / 2.0
		center_cell_position.y += imap_manager.MaxCellSize / 2.0
		var dist_to: float = center_cell_position.distance_to(global_position)
		if dist_to >= imap_manager.DefaultCellSize / 2.0:
			update_registry_cell.emit()
			registry_cell = current_registry_cell
	
	# Rare GUI Updates
	CenterCombatHUD.position = position
	ConstantSizedGUI.scale = Vector2.ONE
	if CombatCamera != null and CombatCamera.enabled:
		ConstantSizedGUI.scale = Vector2(1 / CombatCamera.zoom.x, 1 / CombatCamera.zoom.y)
		# if one wants to make the manually controlled hud less transparent than friendly ships
		#var current_color: Color = ConstantSizedGUI.modulate
		#ConstantSizedGUI.modulate = Color(current_color.r, current_color.g, current_color.b, 255)
	
	if camera_feed == true:
		CombatCamera.global_position = self.global_position
	
	if manual_control == false:
		return
	
	#if %TacticalMapLayer.visible == false: # Allow input and messing with the combat camera only if TacticalMap is not visible
	if manual_control == true:
		CombatCamera.position_smoothing_enabled = false # If the tactical map IS visible, we want camera movement to be snappy and instant.
		if TacticalMapLayer.visible == false and TacticalDataDrawing.camera_feed_active == false:
			CombatCamera.position_smoothing_enabled = true # If not visible, we want it be smooth for freelook and panning.
			if Input.is_action_pressed("select") and flux_overload == false and vent_flux_flag == false:
				fire_weapon_system(selected_weapon_system.weapons)
			var rotate_direction: Vector2 = Vector2(0, Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left"))
			rotate_angle = rotate_direction.angle()
			var adjust_mass: float = (mass * 1000)
			rotate_angle = rotate_angle * adjust_mass * ship_stats.turn_rate
			move_direction = Vector2(Input.get_action_strength("accelerate") - Input.get_action_strength("decelerate"),
			Input.get_action_strength("strafe_right") - Input.get_action_strength("strafe_left")).normalized()
			
			if Input.is_action_pressed("vent_flux"):
				vent_flux_flag = true
		if TacticalDataDrawing.camera_feed_active == false:
			ManualControlHUD.update_hud()
			if manual_camera_freelook == false:
				CombatCamera.global_position = self.global_position
			#CombatCamera.position_smoothing_enabled = true # Set to false when initially set to allow "snappy" behavior.

	var true_direction: Vector2 = move_direction.rotated(transform.x.angle())
	var velocity = 0.0
	var speed_modifier: float = 0.0
	if (soft_flux + hard_flux) == 0.0:
		speed_modifier = zero_flux_bonus
	
	velocity = (speed + speed_modifier) * time
	velocity *= true_direction
	if move_direction == Vector2.ZERO:
		time = 0.0
	elif velocity.length() < (speed + speed_modifier):
		time += delta + time_coefficient
	
	velocity = velocity.limit_length(speed + speed_modifier)
	acceleration = velocity
	
	if (acceleration.abs().floor() != Vector2.ZERO or manual_control) and sleeping:
		sleeping = false
	
	# Storing this in a dark, dark corner, just in case
	# quadratic
	#velocity = ship_stats.acceleration * time ** 2 
	# cubic
	#velocity = ship_stats.acceleration * time ** 3
	# exponential
	#velocity = ship_stats.acceleration * 2 ** (10 * (time - 1))
	# sigmoid
	#velocity = ship_stats.acceleration / (1 + exp(-time))

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var force: Vector2 = acceleration
	
	if manual_control == false:
		apply_force(force)
	elif manual_control == true:
		apply_force(force)
		apply_torque(rotate_angle)
	
	if match_velocity_flag == true:
		state.linear_velocity = state.linear_velocity.limit_length(match_speed)
	else:
		state.linear_velocity = state.linear_velocity.limit_length(speed)
	
	# use apply_impulse for one-shot calculations for collisions
	# its time-independent hence why its a one-shot

func _on_target_in_range(value: bool) -> void:
	if target_unit == null and target_in_range == true and value == false:
		target_in_range = value
		return
	
	if combat_flag == false:
		return
	
	if value == false and (fallback_flag == true or retreat_flag == true):
		return
	
	if value == true:
		target_in_range = true
		return
	
	var oor_count: int = 0
	for weapon in all_weapons:
		if target_unit.get_rid() == weapon.primary_target and weapon.can_fire == false:
			oor_count += 1
	
	if oor_count == all_weapons.size():
		target_in_range = false

func set_combat_ai(value: bool) -> void:
	if value == true and group_leader == true and ShipNavigationAgent.is_navigation_finished() == false:
		set_navigation_position(position)
	CombatBehaviorTree.ToggleRoot(value)
	for weapon in all_weapons:
		weapon.AI_enabled = value
		weapon.auto_aim = true
		weapon.auto_fire = true

func set_blackboard_data(key: Variant, value: Variant) -> void:
	var blackboard = CombatBehaviorTree.blackboard
	blackboard.set_data(key, value)

func remove_blackboard_data(key: Variant) -> void:
	var blackboard = CombatBehaviorTree.blackboard
	blackboard.remove_data(key)

func set_target_unit(target) -> void:
	if target is RigidBody2D:
		target_unit = target
	else:
		target_unit = null

func set_targets(targets: Array) -> void:
	var recast_targets: Array[RigidBody2D] = []
	for n_target in targets:
		if n_target == null:
			continue
		if n_target is Ship:
			recast_targets.append(n_target)
		else:
			push_error("Expected a RigidBody2D, got: " + str(n_target))
	targeted_units = recast_targets
	if targets.is_empty() == false and target_position != Vector2.ZERO:
		target_position = Vector2.ZERO

func set_goal_flag(value) -> void:
	goal_flag = value

func set_deploy_flag(value) -> void:
	deploy_flag = value

func set_fallback_flag(value) -> void:
	fallback_flag = value

func generate_combat_probability(enemy: Ship) -> float:
	var agent_inf: float = abs(approx_influence)
	var target_inf: float = abs(enemy.approx_influence)
	var threat_weight: float = agent_inf / (agent_inf + target_inf)
	var flux_weight: float = total_flux / (enemy.total_flux + total_flux)
	var weapon_modifier: float = enemy.all_weapons.size() / all_weapons.size()
	var prob: float = (threat_weight + flux_weight) / (2.0 * weapon_modifier)
	return prob

# Feel like this is obvious if you need to write a comment to make more sense of it be my guest.
func collision_raycast(from: Vector2, to: Vector2, collision_bitmask: int, test_area: bool, test_body: bool) -> Dictionary:
	var results: Dictionary = {}
	
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to, collision_bitmask, [self])
	query.collide_with_areas = test_area
	query.collide_with_bodies = test_body
	results = space_state.intersect_ray(query)
	return results

# Translating the center of a circle with the target position.
func translate_radial_vector(direction: Vector2, radius: float) -> Vector2:
	var translation: Vector2 = Vector2(direction.x * radius, direction.y * radius)
	var new_vector: Vector2 = Vector2(target_position.x + translation.x, target_position.y + translation.y)
	return new_vector

# idk how to explain this it does a radial vector sweep there literally exists a function called Sweep2D or whatever
# that i didnt use because it didnt work well with area2d's and this approach does
func radial_vector_sweep(ship_query: Dictionary, target_query: Dictionary, start_angle: float, increment_angle: float, sweep_range: int) -> Array[Vector2]:
	var sweep_vectors: Array[Vector2] = []
	if ship_query.is_empty() or target_query.is_empty():
		return sweep_vectors
	
	#collider: The colliding object.
	#collider_id: The colliding object's ID.
	#normal: The object's surface normal at the intersection point, or Vector2(0, 0) if the ray starts inside the shape and PhysicsRayQueryParameters2D.hit_from_inside is true.
	#position: The intersection point.
	#rid: The intersecting object's RID.
	#shape: The shape index of the colliding shape.
	
	# flip the direction of the raycast normal to make it face the collider
	var target_direction: Vector2 = -1*target_query["normal"]
	
	# find the distance from the target position to the intersection
	var intersection_position: Vector2 = ship_query["position"]
	var sweep_radius: float = target_position.distance_to(intersection_position)
	
	# get the radial vectors using the sweep radius
	var new_sweep_direction: Vector2 = target_direction.rotated(start_angle)
	for i in range(sweep_range): # no, "i" does nothing here, rewrite this approach if bothers you
		new_sweep_direction = new_sweep_direction.rotated(increment_angle)
		sweep_vectors.push_back(translate_radial_vector(new_sweep_direction, sweep_radius))
	
	return sweep_vectors

# Do a raycast from to local target position to the vector position. Should return valid paths.
func raycast_sweep(sweep_vectors: Array[Vector2], local_target_pos: Vector2) -> Array[Vector2]:
	var valid_paths: Array[Vector2] = []
	if sweep_vectors.is_empty():
		return valid_paths
	 
	var skip_next_entry: bool = false
	for vector in sweep_vectors:
		if skip_next_entry:
			# hokey workaround for removing paths around an invalid path that are likely to cause collisions
			skip_next_entry = false
			continue
		
		var raycast_results: Dictionary = collision_raycast(local_target_pos, vector, 7, true, false)
		if raycast_results.is_empty():
			valid_paths.push_back(vector)
		else:
			valid_paths.pop_back() # remove previous valid entry
			skip_next_entry = true
	
	return valid_paths

func _on_SeparationShape_body_entered(neighbor) -> void:
	if neighbor == self or neighbor is StaticBody2D or neighbor is ShieldSlot:
		return
	var n_neighbor: RigidBody2D = neighbor as RigidBody2D
	var tmp_array: Array = separation_neighbors
	if neighbor.is_friendly == is_friendly:
		tmp_array.append(n_neighbor)
	separation_neighbors = tmp_array

func _on_SeparationShape_body_exited(neighbor) -> void:
	if neighbor is StaticBody2D:
		return
	var tmp_array: Array = separation_neighbors
	tmp_array.erase(neighbor)
	separation_neighbors = tmp_array

func _on_AvoidanceShape_body_entered(body) -> void:
	if body == self or body is StaticBody2D:
		return
	var tmp_array = neighbor_units
	tmp_array.append(body)
	neighbor_units = tmp_array

func _on_AvoidanceShape_body_exited(body) -> void:
	if body == self or body is StaticBody2D:
		return
	var tmp_array = []
	for unit in neighbor_units:
		if body == unit:
			continue
		tmp_array.append(unit)
	neighbor_units = tmp_array

func _on_AvoidanceShape_area_entered(projectile) -> void:
	if projectile.collision_layer != 8 or projectile.is_friendly == is_friendly:
		return
	
	var ship_id = get_rid().get_id()
	if projectile.ship_id == ship_id:
		return
	
	if projectile not in incoming_projectiles:
		incoming_projectiles.append(projectile)
	
	combat_flag = true
	CombatTimer.start()

func _on_AvoidanceShape_area_exited(projectile) -> void:
	if projectile.collision_layer != 8 or projectile.is_friendly == is_friendly:
		return
	
	var ship_id = get_rid().get_id()
	if projectile.ship_id == ship_id:
		return
	
	if projectile in incoming_projectiles:
		incoming_projectiles.erase(projectile)

func _on_body_entered(body):
	if retreat_flag == true and body is StaticBody2D and body is not ShieldSlot:
		print(name, " successfully retreated")
		set_collision_mask_value(2, false)
		destroy_ship()

func _on_CombatTimer_timeout():
	combat_flag = false

func _on_RetreatTimer_timeout():
	queue_free()

func _on_OverloadTimer_timeout():
	flux_overload = false
	for weapon in all_weapons:
			weapon.flux_overload = flux_overload
