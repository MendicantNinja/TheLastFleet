@icon("res://Art/MetaIcons/BehaviorTree/tree.svg")
extends BehaviorTree
class_name BehaviorTreeRoot

const BLACKBOARD = preload("res://Scripts/CombatGUIScripts/CombatAI/BehaviorTree/blackboard.gd")

@export var enabled: bool = true

@onready var blackboard = BLACKBOARD.new()
@onready var agent = get_parent()

func _ready() -> void:
	if get_child_count() != 1:
		toggle_root(false)
		return

func _physics_process(delta) -> void:
	if not enabled:
		return
	
	get_child(0).tick(agent, blackboard)

func toggle_root(value: bool) -> void:
	enabled = value
