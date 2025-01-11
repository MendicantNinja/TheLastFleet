extends CanvasLayer

var current_ship: Ship = null
@onready var HUDWrapper: Control = $HUDWrapper

@onready var HardFluxIndicator = $HUDWrapper/HardFluxIndicator
@onready var SoftFluxIndicator = $HUDWrapper/HardFluxIndicator/SoftFluxIndicator
@onready var FluxPip = $HUDWrapper/HardFluxIndicator/FluxPip
@onready var HullIntegrityIndicator = $HUDWrapper/HullIntegrityIndicator

@onready var WeaponList = $HUDWrapper/WeaponList
@onready var weapon_system_scene = load("res://Scenes/GUIScenes/CombatGUIScenes/ManualHUDWeaponElement.tscn")

func set_ship(ship: Ship) -> void:
	print(ship)
	current_ship = ship
	if current_ship == null:
		self.visible = false
		return
	setup_weapon_systems()
	update_hud()

func setup_weapon_systems() -> void:
	for weapon_system in current_ship.ship_stats.weapon_systems:
		print("setup called")
		if weapon_system.weapons.is_empty() == false:
			print("is not empty true")
			var weapon_system_instance: GridContainer = weapon_system_scene.instantiate()
			weapon_system_instance.initialize(weapon_system)
			WeaponList.add_child(weapon_system_instance)
			

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
	
func _draw() -> void:
	
	pass
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
