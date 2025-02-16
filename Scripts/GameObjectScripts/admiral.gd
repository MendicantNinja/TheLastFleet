extends Node2D
class_name Admiral

@onready var AdmiralAI: BehaviorTreeRoot = $AdmiralAI
@onready var available_units: Array = []

var heuristic_strat: globals.Strategy
var enemy_strength: float = 0.0
var admiral_strength: float = 0.0
var effective_strength: Dictionary = {}

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
var diversion_key: StringName = &"diversion"
var flank_key: StringName = &"flank"

var fallback_flag: bool = false
var retreat_flag: bool = false

func _physics_process(_delta) -> void:
	if available_units.is_empty():
		available_units = get_tree().get_nodes_in_group(&"enemy")
