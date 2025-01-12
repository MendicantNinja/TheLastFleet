extends GridContainer

var Number1: RichTextLabel = null
var NameCount1: RichTextLabel = null
var AutofireIndicator: TextureButton = null
var weapon_subtype_scene = load("res://Scenes/GUIScenes/CombatGUIScenes/ManualHUDWeaponSubtype.tscn")



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func initialize(weapon_system: WeaponSystem) -> void:
	Number1 = $Row1/Number
	NameCount1 = $Row1/NameCount
	AutofireIndicator = $Row1/AutofireIndicator
	Number1.text = str(weapon_system.weapons[0].weapon_system_group+1) + ")"
	# Identify all weapon types in the weapon system group. Then group them together.
	var weapon_type_counts: Dictionary = {}

	for weapon_slot in weapon_system.weapons:
		var weapon_name: String = weapon_slot.weapon.weapon_name.to_upper()
		if weapon_type_counts.has(weapon_name):
			weapon_type_counts[weapon_name] += 1
		else:
			weapon_type_counts[weapon_name] = 1
	
	var row_index = 1
	for weapon_name in weapon_type_counts.keys():
		#if row_index > 4:
			#break  # Assume a maximum of 4 rows/weapon types in the GUI for simplicity
		if row_index == 1:
			NameCount1.text = str(weapon_type_counts.get(weapon_name, 0)) + "X " + weapon_name.to_upper()
		else:
			var instanced_subrow = weapon_subtype_scene.instantiate()
			add_child(instanced_subrow)
			instanced_subrow.NameCount.text = str(weapon_type_counts.get(weapon_name, 0)) + "X " + weapon_name.to_upper()
		row_index += 1
	pass

func toggle_autofire() -> void:
	AutofireIndicator.pressed
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
