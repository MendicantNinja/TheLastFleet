extends CanvasLayer

var current_ship: Ship = null
@onready var HUDWrapper: Control = $HUDWrapper

@onready var HardFluxIndicator = $HUDWrapper/HardFluxIndicator
@onready var SoftFluxIndicator = $HUDWrapper/HardFluxIndicator/SoftFluxIndicator
@onready var FluxPip = $HUDWrapper/HardFluxIndicator/FluxPip
@onready var HullIntegrityIndicator = $HUDWrapper/HullIntegrityIndicator
@onready var IndicatorDecor = $HUDWrapper/IndicatorDecor

#@onready var WeaponList = $HUDWrapper/IndicatorDecor/WeaponList
@onready var weapon_system_scene = load("res://Scenes/GUIScenes/CombatGUIScenes/ManualHUDWeaponElement.tscn")
@onready var weapon_system_scene_list: Array[GridContainer]
@onready var weapon_system_spacing: Vector2 = Vector2(62, 36)

func set_ship(ship: Ship) -> void:
	print(ship)
	current_ship = ship
	if current_ship == null:
		self.visible = false
		return
	setup_weapon_systems()
	update_hud()

func _unhandled_key_input(event) -> void:
	if self.visible == true:
		if event.ctrl_pressed == true:
			if (event.keycode == KEY_1 and event.pressed):
				weapon_system_scene_list[0].toggle_autofire_pip()
			elif (event.keycode == KEY_2 and event.pressed):
				weapon_system_scene_list[1].toggle_autofire_pip()
			elif (event.keycode == KEY_3 and event.pressed):
				weapon_system_scene_list[2].toggle_autofire_pip()
			elif (event.keycode == KEY_4 and event.pressed):
				weapon_system_scene_list[3].toggle_autofire_pip()
			elif (event.keycode == KEY_5 and event.pressed):
				weapon_system_scene_list[4].toggle_autofire_pip()
			elif (event.keycode == KEY_6 and event.pressed):
				weapon_system_scene_list[5].toggle_autofire_pip()
			elif (event.keycode == KEY_7 and event.pressed):
				weapon_system_scene_list[6].toggle_autofire_pip()
			elif (event.keycode == KEY_8 and event.pressed):
				weapon_system_scene_list[7].toggle_autofire_pip()

func setup_weapon_systems() -> void:
	for child in $HUDWrapper.get_children():
		if child is GridContainer:
			child.queue_free()
	weapon_system_spacing = Vector2(62, 36)
	weapon_system_scene_list.clear()
	if current_ship == null:
		return
	for weapon_system in current_ship.weapon_systems:
		var weapon_system_instance: GridContainer = weapon_system_scene.instantiate()
		weapon_system_scene_list.append(weapon_system_instance)
		if weapon_system.weapons.is_empty() == false:
			weapon_system_instance.initialize(weapon_system)
			$HUDWrapper.add_child(weapon_system_instance)
			weapon_system_instance.position.x = IndicatorDecor.position.x + weapon_system_instance.gui_position.x
			weapon_system_instance.position.y =  IndicatorDecor.position.y + weapon_system_spacing.y
			weapon_system_spacing.y += weapon_system_instance.size.y + 5
	
	if weapon_system_spacing.y >= 36 + 25*6:
		$HUDWrapper.position.y -= 25
		$HUDWrapper/WeaponSystems.position.x += 4
		$HUDWrapper/WeaponSystems.position.y += 3
		IndicatorDecor.scale = Vector2(1.05, 1.25)
	elif weapon_system_spacing.y >= 36 + 25*7:
		print('holy shit thats alot of weapons')
		$HUDWrapper/WeaponSystems.position.x += 8
		$HUDWrapper/WeaponSystems.position.y += 6
		$HUDWrapper.position.y -= 50
		IndicatorDecor.scale = Vector2(1.1, 1.5)
	else: 
		$HUDWrapper.position = Vector2(4, 1076)
		IndicatorDecor.scale = Vector2(1, 1)
		

func toggle_visible() -> void:
	if self.visible == true:
		self.visible = false
	elif self.visible == false:
		self.visible = true

func update_hud() -> void:
	if current_ship != null:
		self.visible = true
		var current_flux: float = current_ship.soft_flux + current_ship.hard_flux
		var flux_rate: float = 100 /  current_ship.total_flux # Returns a factor multiplier of the total flux that can be used to get a percentage. e.g 100/2000 = .05. 
		HardFluxIndicator.value = floor(flux_rate * current_ship.hard_flux)
		SoftFluxIndicator.value = floor(flux_rate * current_ship.soft_flux)
		SoftFluxIndicator.position.x = HardFluxIndicator.value
		FluxPip.position.x = HardFluxIndicator.value - 2
		
		HullIntegrityIndicator.max_value = current_ship.ship_stats.hull_integrity
		HullIntegrityIndicator.value = current_ship.hull_integrity

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
