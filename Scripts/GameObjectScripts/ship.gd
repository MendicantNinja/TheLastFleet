extends RigidBody2D
class_name Ship

@onready var ShipNavigationAgent = $ShipNavigationAgent
@onready var NavigationTimer = $NavigationTimer
@onready var RepathArea = $RepathArea
@onready var RepathShape = $RepathArea/RepathShape
@onready var ShipSprite = $ShipSprite
@onready var CenterCombatHUD = $CenterCombatHUD
@onready var SoftFluxIndicator = $CenterCombatHUD/SoftFluxIndicator
@onready var HardFluxIndicator = $CenterCombatHUD/HardFluxIndicator
@onready var HullIntegrityIndicator = $CenterCombatHUD/HullIntegrityIndicator
@onready var ManualControlIndicator = $CenterCombatHUD/ManualControlIndicator
@onready var ShipTargetIcon = $CenterCombatHUD/ShipTargetIcon
@onready var TacticalMapIcon = $CenterCombatHUD/TacticalMapIcon
@onready var CombatBehaviorTree = $CombatBehaviorTree
@onready var all_weapons: Array[WeaponSlot]

var ManualControlCamera: Camera2D = null

# Temporary variables
# Should group weapon slots in the near future instead of this, 
# even though call_group() broke in 4.3 stable.
@onready var ShieldSlot = $ShieldSlot
@onready var ShieldArea = $ShieldSlot/Shields
@onready var ShieldShape = $ShieldSlot/Shields/ShieldShape

# ship stats
var ship_stats: ShipStats
var speed: float = 0.0
var hull_integrity: float = 0.0
var armor: float = 0.0
var shield_radius: float = 0.0
var total_flux: float = 0.0
var soft_flux: float = 0.0
var hard_flux: float = 0.0
var shield_upkeep: float = 0.0
var shield_toggle: bool = false
var flux_overload: bool = false
var targeted: bool = false

var is_friendly: bool = false # For friendly NPC ships (I love three-party combat) 
var manual_control: bool = false:
	set(value):
		if value == false:
			ManualControlIndicator.visible = false
			manual_control = false
		elif value == true:
			ManualControlIndicator.visible = true
			manual_control = true
var rotate_angle: float = 0.0
var move_direction: Vector2 = Vector2.ZERO

# Used for targeting and weapons.
var aim_direction: Vector2 = Vector2.ZERO
var mouse_hover: bool = false

# camera goodies
var zoom_in_limit: Vector2 = Vector2(1.2, 1.2)
var zoom_out_limit: Vector2 = Vector2(0.6, 0.6)
var zoom_value: Vector2 = Vector2.ONE

# group/unit stuff
var group_name: StringName = &""
var group_leader: bool = false
var group_transform: Transform2D = Transform2D.IDENTITY
var group_velocity: Vector2 = Vector2.ZERO
var posture: StringName = &""
var idle: bool = true

# Used for combat AI / behavior tree / influence map
var template_maps: Dictionary = {}
var template_cell_indices: Dictionary = {}
var target_in_range: bool = false
var prev_position: Vector2 = Vector2.ZERO
#var adj_template_maps: Dictionary = {}

# Used for navigation
var final_target_position: Vector2 = Vector2.ZERO
var next_path_position: Vector2 = Vector2.ZERO
var intermediate_pathing: bool = false
var acceleration: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var movement_delta: float = 0.0
var rotational_delta: float = 0.0
var ship_select: bool = false:
	set(value):
		if value == true: 
			TacticalMapIcon.button_pressed = true # Pressed is solely for GUI effects (brighten) with regards to the TacMapIcon.
			ship_select = value
		elif value == false:
			TacticalMapIcon.button_pressed = false
			ship_select = value
		ship_selected.emit()

# Custom signals.
signal alt_select()
signal switch_to_manual()
signal camera_removed()
signal request_manual_camera()
signal ship_selected()
signal destroyed()
signal update_agent_influence(last_position)

func initialize(p_ship_stats: ShipStats = ShipStats.new(data.ship_type_enum.TEST)) -> void:
	ship_stats = p_ship_stats

# Any adjustments before deploying the ship to the combat space. Called during/by FleetDeployment.
func deploy_ship() -> void:
	TacticalMapIcon.texture_normal = load("res://Art/CombatGUIArt/tac_map_player_ship.png")
	TacticalMapIcon.texture_pressed = load("res://Art/CombatGUIArt/tac_map_player_ship_selected.png")
	var minimum_size = Vector2(RepathShape.shape.radius, RepathShape.shape.radius) * 2.0
	TacticalMapIcon.custom_minimum_size = minimum_size + minimum_size * ShipSprite.scale
	TacticalMapIcon.pivot_offset = Vector2(TacticalMapIcon.size.x/2, TacticalMapIcon.size.y/2)
	if is_friendly == true:
		TacticalMapIcon.modulate = settings.player_color
		ManualControlIndicator.self_modulate = settings.player_color
		$ShipLivery.self_modulate = settings.player_color
	elif is_friendly == false:
		# Non-identical to is_friendly == true Later in development. Swap these rectangle pictures with something else. (Starsector uses diamonds for enemies).
		TacticalMapIcon.modulate = settings.enemy_color
		$ShipLivery.self_modulate = settings.enemy_color

func _ready() -> void:
	ShipSprite.z_index = 0
	$ShipLivery.z_index = 1
	
	if ship_stats == null:
		ship_stats = ShipStats.new(data.ship_type_enum.TEST)
	speed = ship_stats.top_speed
	
	var ship_hull = ship_stats.ship_hull
	ShipSprite.texture = ship_hull.ship_sprite
	hull_integrity = ship_hull.hull_integrity
	armor = ship_hull.armor
	#ShipSprite.self_modulate = settings.player_color
	
	var repath_shape: Shape2D = CircleShape2D.new()
	repath_shape.radius = ShipNavigationAgent.radius
	RepathShape.shape = repath_shape
	RepathArea.collision_layer = collision_layer
	RepathArea.collision_mask = collision_mask
	
	shield_radius = ShipNavigationAgent.radius
	
	shield_upkeep = ship_hull.shield_upkeep
	total_flux = ship_stats.flux
	
	var soft_flux_hud_offset: Vector2 = Vector2(shield_radius, -shield_radius + 3)
	var hard_flux_hud_offset: Vector2 = Vector2(shield_radius, -shield_radius)
	var hull_hud_offset: Vector2 = Vector2(shield_radius, -shield_radius * 0.7)
	var target_ship_offset: Vector2 = Vector2(-shield_radius, shield_radius)
	var manual_control_offset: Vector2 = Vector2(shield_radius, shield_radius) * -1.2
	SoftFluxIndicator.position = soft_flux_hud_offset
	HardFluxIndicator.position = hard_flux_hud_offset
	HullIntegrityIndicator.position = hull_hud_offset
	ShipTargetIcon.position = target_ship_offset
	ManualControlIndicator.position = manual_control_offset
	
	ManualControlIndicator.visible = false
	ShipTargetIcon.visible = false
	HullIntegrityIndicator.max_value = ship_stats.hull_integrity
	HullIntegrityIndicator.value = hull_integrity
	
	# TEMPORARY FIX FOR MENDI'S AMUSEMENTON
	#ShipSprite.modulate = self_modulate
	var occupancy_template: ImapTemplate
	var threat_template: ImapTemplate
	add_to_group(&"agent")
	if collision_layer == 1:
		occupancy_template = imap_manager.template_maps[imap_manager.TemplateType.INVERT_OCCUPANCY_TEMPLATE]
		template_maps[imap_manager.MapType.OCCUPANCY_MAP] = occupancy_template.template_maps[1]
		threat_template = imap_manager.template_maps[imap_manager.TemplateType.INVERT_THREAT_TEMPLATE]
		template_maps[imap_manager.MapType.THREAT_MAP] = threat_template.template_maps[3]
		add_to_group(&"friendly")
		is_friendly = true
		rotation -= PI/2
		CombatBehaviorTree.toggle_root(false)
	else:
		occupancy_template = imap_manager.template_maps[imap_manager.TemplateType.OCCUPANCY_TEMPLATE]
		template_maps[imap_manager.MapType.OCCUPANCY_MAP] = occupancy_template.template_maps[1]
		threat_template = imap_manager.template_maps[imap_manager.TemplateType.THREAT_TEMPLATE]
		template_maps[imap_manager.MapType.THREAT_MAP] = threat_template.template_maps[3]
		add_to_group(&"enemy")
		CombatBehaviorTree.toggle_root(true)
		rotation += PI/2
	
	# Assigns weapon slots based on what's in the ship scene.
	for child in get_children():
		if child is WeaponSlot:
			all_weapons.append(child)
			child.detection_parameters(collision_mask, is_friendly, get_rid())
			child.weapon_slot_fired.connect(_on_Weapon_Slot_Fired)
			child.target_in_range.connect(_on_target_in_range)
	
	for i in range(all_weapons.size()):
		# Placeholder
		all_weapons[i].set_weapon_slot(data.weapon_dictionary.get(data.weapon_enum.RAILGUN))
		#Gets data from ship_stats, may need to be moved to initialize(p_ship_stats). 
		#all_weapons[i].set_weapon_slot(ship_stats.weapon_slots[i].weapon) 
	
	deploy_ship()
	toggle_auto_aim(all_weapons)
	toggle_auto_fire(all_weapons)
	self.input_event.connect(_on_input_event)
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)

func process_damage(projectile: Projectile) -> void:
	if CombatBehaviorTree.enabled == false:
		CombatBehaviorTree.enabled = true
	
	var armor_damage_reduction: float = projectile.damage / (projectile.damage + armor)
	armor -= armor_damage_reduction
	var hull_damage: float = armor_damage_reduction * projectile.damage
	hull_integrity -= hull_damage
	HullIntegrityIndicator.value = hull_integrity
	if hull_integrity <= 0.0:
		destroy_ship()
	if projectile.damage_type == data.weapon_damage_enum.KINETIC:
		globals.play_audio_pitched(load("res://Sounds/Combat/ProjectileHitSounds/kinetic_hit.wav"), projectile.position)

func destroy_ship() -> void:
	destroyed.emit()
	remove_from_group(group_name)
	remove_from_group(&"agent")
	var group: Array = get_tree().get_nodes_in_group(group_name)
	if group_leader == true and group.size() > 1:
		var unit_range: int = group.size() - 1
		var pick_leader: int = randi_range(0, unit_range)
		var new_leader: Ship = group[pick_leader]
		new_leader.set_group_leader(true)
	ShipTargetIcon.visible = false
	queue_free()

func toggle_shield() -> void:
	if not shield_toggle and flux_overload:
		return
	
	if not shield_toggle:
		shield_toggle = true
		ShieldSlot.shield_parameters(1, shield_radius, collision_layer, get_rid().get_id())
		ShieldSlot.shield_hit.connect(_on_Shield_Hit)
	elif shield_toggle:
		shield_toggle = false
		ShieldSlot.shield_parameters(-1, shield_radius, collision_layer, get_rid().get_id())
		ShieldSlot.shield_hit.disconnect(_on_Shield_Hit)

func set_shields(value: bool) -> void:
	shield_toggle = value
	if value == true:
		ShieldSlot.shield_parameters(1, shield_radius, collision_layer, get_rid().get_id())
		ShieldSlot.shield_hit.connect(_on_Shield_Hit)
	else:
		ShieldSlot.shield_parameters(-1, shield_radius, collision_layer, get_rid().get_id())
		ShieldSlot.shield_hit.disconnect(_on_Shield_Hit)

func _on_Weapon_Slot_Fired(flux_cost) -> void:
	soft_flux += flux_cost
	update_flux_indicators()

func _on_Shield_Hit(damage: float, damage_type: int) -> void:
	hard_flux += damage * ship_stats.shield_efficiency
	update_flux_indicators()

func update_flux_indicators() -> void:
	var current_flux: float = soft_flux + hard_flux
	if current_flux >= total_flux and not flux_overload:
		flux_overload = true
		for weapon in all_weapons:
			weapon.update_flux_overload(flux_overload)
		return
	elif current_flux < total_flux and flux_overload:
		flux_overload = false
		for weapon in all_weapons:
			weapon.update_flux_overload(flux_overload)
	
	var flux_rate: float = 100 / total_flux
	HardFluxIndicator.texture_progress_offset.x = floor(flux_rate * hard_flux)
	SoftFluxIndicator.value = flux_rate * soft_flux

func display_icon(value: bool) -> void:
	TacticalMapIcon.visible = value

# Units/Groups

func group_remove(n_group_name: StringName) -> void:
	if group_leader and n_group_name == group_name:
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

func set_group_leader(leader_value: bool) -> void:
	print("%s made leader of %s" % [name, group_name])
	group_leader = leader_value

func set_idle_flag(value: bool) -> void:
	idle = value

func add_manual_camera(camera: Camera2D, n_zoom_value: Vector2) -> void:
	if not ship_select:
		return
	add_child(camera)
	ManualControlCamera = camera
	ManualControlCamera.enabled = true
	zoom_value = n_zoom_value
	if n_zoom_value > zoom_out_limit:
		zoom_value = zoom_out_limit
	elif n_zoom_value < zoom_in_limit:
		zoom_value = zoom_in_limit

#ooooo ooooo      ooo ooooooooo.   ooooo     ooo ooooooooooooo 
#`888' `888b.     `8' `888   `Y88. `888'     `8' 8'   888   `8 
 #888   8 `88b.    8   888   .d88'  888       8       888      
 #888   8   `88b.  8   888ooo88P'   888       8       888      
 #888   8     `88b.8   888          888       8       888      
 #888   8       `888   888          `88.    .8'       888      
#o888o o8o        `8  o888o           `YbodP'        o888o    

# Any generic input event.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("m2") and manual_control:
			toggle_shield()
		elif Input.is_action_just_pressed("zoom in") and manual_control and zoom_value < zoom_in_limit:
			zoom_value += Vector2(0.01, 0.01)
		elif Input.is_action_just_pressed("zoom out") and manual_control and zoom_value > zoom_out_limit:
			zoom_value -= Vector2(0.01, 0.01)
	elif event is InputEventKey:
		if is_friendly:
			if (event.keycode == KEY_T and event.pressed) and ship_select:
				toggle_manual_control()
			elif (event.keycode == KEY_C and event.pressed) and manual_control:
				toggle_auto_aim(all_weapons)
			elif (event.keycode == KEY_V and event.pressed) and manual_control:
				toggle_auto_fire(all_weapons)
			elif (event.keycode == KEY_TAB and event.pressed) and manual_control:
				toggle_manual_control()
				camera_removed.emit()
		elif not is_friendly: # for non-player/enemy ships
			if (event.keycode == KEY_R and event.pressed) and not mouse_hover:
				targeted = false
				ShipTargetIcon.visible = false
				_on_mouse_exited()
			elif (event.keycode == KEY_R and event.pressed) and mouse_hover:
				emit_signal("ship_targeted", get_rid())
				targeted = true
				ShipTargetIcon.visible = true

func _on_input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	# This may end up disrupting drag by handling the input too early. Look for a manual "input == not handled" function later if needed.
	if event is InputEventMouseButton:
		if Input.is_action_pressed("alt select") and Input.is_action_just_pressed("select"):
			alt_select.emit()
			return
		if Input.is_action_just_pressed("select") and is_friendly and not ship_select:
			ship_select = true # select ship
		elif Input.is_action_just_pressed("select") and is_friendly and ship_select:
			ship_select = false # deselect ship

func _on_mouse_entered() -> void:
	mouse_hover = true
	for weapon_slot in all_weapons:
		weapon_slot.toggle_display_aim(mouse_hover)

func _on_mouse_exited() -> void:
	mouse_hover = false
	if targeted or (ship_select and manual_control):
		return
	for weapon_slot in all_weapons:
		weapon_slot.toggle_display_aim(mouse_hover)

func highlight_selection(select_value: bool = false) -> void:
	#print("%s is highlighted? %s" % [name, select_value])
	TacticalMapIcon.toggle_mode = select_value
	TacticalMapIcon.button_pressed = select_value
	get_viewport().set_input_as_handled()

func toggle_manual_control() -> void:
	if ship_select == false:
		manual_control = false
		CombatBehaviorTree.toggle_root(true)
		return
	
	if manual_control == false:
		manual_control = true
	elif manual_control == true:
		manual_control = false
		camera_removed.emit(zoom_value, ManualControlCamera.position)
		ManualControlCamera.queue_free()
		ManualControlCamera = null
		ship_select = false
		_on_mouse_exited()
	
	toggle_manual_aim(all_weapons, manual_control)
	
	if manual_control == true and group_leader:
		set_group_leader(false)
	if manual_control == true and is_in_group(group_name):
		remove_from_group(group_name)
		group_name = &""
	if manual_control == true and not ShipNavigationAgent.is_navigation_finished():
		ShipNavigationAgent.set_target_position(position)
	
	if manual_control == true:
		switch_to_manual.emit()
		request_manual_camera.emit()
		CombatBehaviorTree.toggle_root(false)
	else:
		CombatBehaviorTree.toggle_root(true)

#oooooo   oooooo     oooo oooooooooooo       .o.       ooooooooo.     .oooooo.   ooooo      ooo  .oooooo..o 
 #`888.    `888.     .8'  `888'     `8      .888.      `888   `Y88.  d8P'  `Y8b  `888b.     `8' d8P'    `Y8 
  #`888.   .8888.   .8'    888             .8"888.      888   .d88' 888      888  8 `88b.    8  Y88bo.      
   #`888  .8'`888. .8'     888oooo8       .8' `888.     888ooo88P'  888      888  8   `88b.  8   `"Y8888o.  
	#`888.8'  `888.8'      888    "      .88ooo8888.    888         888      888  8     `88b.8       `"Y88b 
	 #`888'    `888'       888       o  .8'     `888.   888         `88b    d88'  8       `888  oo     .d8P 
	  #`8'      `8'       o888ooooood8 o88o     o8888o o888o         `Y8bood8P'  o8o        `8  8""88888P'  

func set_target_for_weapons(unit) -> void:
	for weapon in all_weapons:
		weapon.set_target_unit(unit)

func fire_weapon_system(weapon_system: Array[WeaponSlot]) -> void:
	for weapon_slot in weapon_system:
		fire_weapon_slot(weapon_slot)

func fire_weapon_slot(weapon_slot: WeaponSlot) -> void:
	var ship_id = get_rid().get_id()
	weapon_slot.fire(ship_id)

func toggle_manual_aim(weapon_system: Array[WeaponSlot], manual_aim_value: bool) -> void:
	for weapon_slot in weapon_system:
		weapon_slot.set_manual_aim(manual_aim_value)

func toggle_auto_aim(weapon_system: Array[WeaponSlot]) -> void:
	for weapon_slot in weapon_system:
		weapon_slot.toggle_auto_aim()

func toggle_auto_fire(weapon_system: Array[WeaponSlot]) -> void:
	for weapon_slot in weapon_system:
		weapon_slot.toggle_auto_fire()

#ooooo      ooo       .o.       oooooo     oooo ooooo   .oooooo.          .o.       ooooooooooooo ooooo   .oooooo.   ooooo      ooo 
#`888b.     `8'      .888.       `888.     .8'  `888'  d8P'  `Y8b        .888.      8'   888   `8 `888'  d8P'  `Y8b  `888b.     `8' 
 #8 `88b.    8      .8"888.       `888.   .8'    888  888               .8"888.          888       888  888      888  8 `88b.    8  
 #8   `88b.  8     .8' `888.       `888. .8'     888  888              .8' `888.         888       888  888      888  8   `88b.  8  
 #8     `88b.8    .88ooo8888.       `888.8'      888  888     ooooo   .88ooo8888.        888       888  888      888  8     `88b.8  
 #8       `888   .8'     `888.       `888'       888  `88.    .88'   .8'     `888.       888       888  `88b    d88'  8       `888  
#o8o        `8  o88o     o8888o       `8'       o888o  `Y8bood8P'   o88o     o8888o     o888o     o888o  `Y8bood8P'  o8o        `8  
																																   
func set_navigation_position(to_position: Vector2) -> void:
	intermediate_pathing = false
	target_position = to_position
	ShipNavigationAgent.set_target_position(to_position)
	get_viewport().set_input_as_handled()

func move_follower(n_velocity: Vector2, next_transform: Transform2D) -> void:
	if CombatBehaviorTree.enabled == true:
		set_combat_ai(false)
	if group_leader:
		return
	if not ShipNavigationAgent.is_navigation_finished():
		ShipNavigationAgent.set_target_position(position)
	group_velocity = n_velocity
	group_transform = next_transform

func _physics_process(delta: float) -> void:
	if NavigationServer2D.map_get_iteration_id(ShipNavigationAgent.get_navigation_map()) == 0:
		return
	
	var velocity = Vector2.ZERO
	CenterCombatHUD.position = position
	
	if ShipNavigationAgent.is_navigation_finished() and not manual_control:
		if rotate_angle != 0.0 and move_direction != Vector2.ZERO:
			rotate_angle = 0.0
			move_direction = Vector2.ZERO
	
	if not ShipNavigationAgent.is_navigation_finished() and manual_control:
		ShipNavigationAgent.set_target_position(position)
	
	if Engine.get_physics_frames() % 60 == 0 and global_position != prev_position:
		update_agent_influence.emit(prev_position)
		prev_position = global_position

	if movement_delta == 0.0 or rotational_delta == 0.0:
		movement_delta = speed * delta
		rotational_delta = ship_stats.turn_rate * delta
		ShipNavigationAgent.set_max_speed(movement_delta)
	
	if manual_control and Input.is_action_pressed("vent flux"):
		if soft_flux > 0.0:
			soft_flux -= ship_stats.flux_dissipation
		elif hard_flux > 0.0:
			hard_flux -= ship_stats.flux_dissipation
		update_flux_indicators()
	
	if manual_control and Input.is_action_pressed("select") and not flux_overload:
		fire_weapon_system(all_weapons)
	
	if shield_toggle and not flux_overload:
		soft_flux += shield_upkeep
		update_flux_indicators()
	elif shield_toggle and flux_overload:
		toggle_shield()
	
	if manual_control:
		if ManualControlCamera.zoom != zoom_value:
			ManualControlCamera.zoom = lerp(ManualControlCamera.zoom, zoom_value, 0.5)
		var rotate_direction: Vector2 = Vector2(0, Input.get_action_strength("E") - Input.get_action_strength("Q"))
		rotate_angle = rotate_direction.angle()
		move_direction = Vector2(Input.get_action_strength("W") - Input.get_action_strength("S"),
		Input.get_action_strength("D") - Input.get_action_strength("A"))
	
	# Normal Pathing
	if not ShipNavigationAgent.is_navigation_finished():
		next_path_position = ShipNavigationAgent.get_next_path_position()
		var direction_to_path: Vector2 = global_position.direction_to(next_path_position)
		velocity = direction_to_path * movement_delta
		velocity += ease_velocity(velocity)
		var transform_look_at: Transform2D = transform.looking_at(next_path_position)
		transform = transform.interpolate_with(transform_look_at, rotational_delta)
	
	if rotate_angle != 0.0:
		var adjust_mass: float = (mass * 1000)
		rotate_angle = rotate_angle * adjust_mass * ship_stats.turn_rate
	
	if move_direction != Vector2.ZERO:
		var rotate_movement: Vector2 = move_direction.rotated(transform.x.angle())
		velocity = rotate_movement * movement_delta
		velocity += ease_velocity(velocity)
	
	if group_leader and not ShipNavigationAgent.is_navigation_finished():
		get_tree().call_group(group_name, "move_follower", velocity, transform)
	
	if not group_leader and not group_name.is_empty() and group_velocity != Vector2.ZERO:
		velocity = group_velocity
		group_velocity = Vector2.ZERO
		var rotate_to: float = transform.x.angle_to(group_transform.x)
		var transform_look_at: Transform2D = transform.rotated_local(rotate_to)
		transform = transform.interpolate_with(transform_look_at, ship_stats.turn_rate)
	
	acceleration = velocity - linear_velocity
	
	if (acceleration.abs().floor() != Vector2.ZERO or manual_control) and sleeping:
		sleeping = false

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var force: Vector2 = acceleration
	
	#if force == Vector2.ZERO:
		#linear_velocity = linear_velocity
	
	if force.abs().floor() != Vector2.ZERO and not manual_control:
		apply_torque(rotate_angle)
		apply_force(force)
	
	if manual_control:
		apply_torque(rotate_angle)
		apply_force(force)
	
	# use apply_impulse for one-shot calculations for collisions
	# its time-independent hence why its a one-shot

func ease_velocity(velocity: Vector2) -> Vector2:
	var new_velocity: Vector2 = Vector2.ZERO
	var normalize_velocity_x: float = linear_velocity.x / velocity.x
	var normalize_velocity_y: float = linear_velocity.y / velocity.y
	if velocity.x == 0.0:
		normalize_velocity_x = 0.0
	if velocity.y == 0.0:
		normalize_velocity_y = 0.0
	new_velocity.x = (velocity.x + linear_velocity.x) * ease(normalize_velocity_x, ship_stats.acceleration)
	new_velocity.y = (velocity.y + linear_velocity.y) * ease(normalize_velocity_y, ship_stats.acceleration)
	return new_velocity

func _on_target_in_range(value: bool) -> void:
	target_in_range = value

func set_combat_ai(value: bool) -> void:
	if value == true and group_leader == true and not ShipNavigationAgent.is_navigation_finished():
		set_navigation_position(position)
	CombatBehaviorTree.toggle_root(value)

func set_blackboard_data(key: Variant, value: Variant) -> void:
	var blackboard = CombatBehaviorTree.blackboard
	blackboard.set_data(key, value)

func remove_blackboard_data(key: Variant) -> void:
	var blackboard = CombatBehaviorTree.blackboard
	blackboard.remove_data(key)

func update_available_target_connections(target_group_key: StringName) -> void:
	var blackboard = CombatBehaviorTree.blackboard
	var target_key: StringName = &"target"
	var available_targets: Array = []
	
	available_targets = blackboard.ret_data(target_group_key)
	for target in available_targets:
		if target == null:
			continue
		if not target.destroyed.is_connected(blackboard._on_target_destroyed):
			target.destroyed.connect(blackboard._on_target_destroyed.bind(target, target_group_key, target_key))

func find_closest_target(available_targets: Array) -> Ship:
	var closest_target: Ship = null
	var distances: Dictionary = {}
	
	for target in available_targets:
		if target == null:
			continue
		var distance_to: float = position.distance_to(target.position)
		distances[distance_to] = target
	
	if not distances.is_empty():
		var shortest_distance: float = distances.keys().min()
		closest_target = distances[shortest_distance]
	
	return closest_target

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

func pick_path(valid_paths: Array[Vector2]) -> Vector2:
	var valid_path_range: int = valid_paths.size() - 1
	var random_entry: int = randi_range(0, valid_path_range)
	return valid_paths[random_entry]

func _on_NavigationTimer_timeout() -> void:
	if ShipNavigationAgent.is_navigation_finished():
		NavigationTimer.stop()
		return
	
	var target_query: Dictionary = {}
	var ship_query: Dictionary = {}
	ship_query = collision_raycast(global_position, target_position, 7, true, false)
	var sweep_vectors: Array[Vector2] = []
	if not ship_query.is_empty():
		var collider_instance: Node = instance_from_id(ship_query["collider_id"])
		var collider_center: Vector2 = collider_instance.global_position
		target_query = collision_raycast(target_position, collider_center, 7, true, false)
		var start_angle: float = -PI/8
		var increment_angle: float = PI/64
		var sweep_range: int = 16
		sweep_vectors = radial_vector_sweep(ship_query, target_query, start_angle, increment_angle, sweep_range)
	
	if sweep_vectors.is_empty():
		ShipNavigationAgent.set_target_position(target_position)
		return
	
	var valid_paths: Array[Vector2] = raycast_sweep(sweep_vectors, target_position)
	if not ship_query.is_empty() and valid_paths.is_empty():
		valid_paths = raycast_sweep(sweep_vectors, global_position)
	elif not valid_paths.is_empty():
		ShipNavigationAgent.set_target_position(pick_path(valid_paths))


func _on_ShipNavigationAgent_velocity_computed(safe_velocity):
	if safe_velocity != Vector2.ZERO:
		linear_velocity += safe_velocity / 2.0
