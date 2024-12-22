extends Node2D
class_name Admiral

@onready var AdmiralAI: BehaviorTreeRoot = $AdmiralAI
@onready var available_units: Array = []

var available_groups: Dictionary = {}
var group_leaders: Dictionary = {}
var order_groups: Array = []
var group_targets: Dictionary = {}

var initial_unit_count: int = 0
var units_destroyed: int = 0
var groups_destroyed: int = 0
var assign_new_leader_group: StringName = &""

var iterator: int = 0
var enemy_group_key_prefix: StringName = &"Enemy Group "
var group_targets_key_suffix: StringName = &" targets"
var target_key: StringName = &"target"

func _ready() -> void:
	process_mode = PROCESS_MODE_PAUSABLE

func _physics_process(_delta) -> void:
	if available_units.is_empty():
		available_units = get_tree().get_nodes_in_group(&"enemy")
		initial_unit_count = available_units.size()

func _on_unit_destroyed(unit, group_name: StringName) -> void:
	units_destroyed += 1
	available_groups[group_name].erase(unit)
	if available_groups[group_name].is_empty():
		groups_destroyed += 1
		available_groups.erase(group_name)

func _on_leader_destroyed(unit, group_name: StringName) -> void:
	units_destroyed += 1
	available_groups[group_name].erase(unit)
	if available_groups[group_name].is_empty():
		groups_destroyed += 1
		available_groups.erase(group_name)
	else:
		assign_new_leader_group = available_groups[group_name]

func _on_target_destroyed(group_name: StringName) -> void:
	group_targets.erase(group_name)
	get_tree().call_group(group_name, "set_idle_flag", true)
