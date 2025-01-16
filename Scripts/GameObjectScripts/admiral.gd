extends Node2D
class_name Admiral

@onready var AdmiralAI: BehaviorTreeRoot = $AdmiralAI
@onready var available_units: Array = []

var heuristic_strat: globals.Strategy

var unit_clusters: Array = []
var enemy_clusters: Array = []
var enemy_vulnerability: Dictionary = {}
var vulnerable_targets: Dictionary = {}
var isolated_targets: Array = []

var group_key_prefix: StringName = &"Enemy Group "
var assign_new_leader_group: StringName = &""
var iterator: int = 0

var available_groups: Dictionary = {}
var awaiting_orders: Array = []
var queue_orders: Dictionary = {}
var move_key: StringName = &"move"
var target_key: StringName = &"target"
var posture_key: StringName = &"posture"

var initial_unit_count: int = 0
var units_destroyed: int = 0
var groups_destroyed: int = 0

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
