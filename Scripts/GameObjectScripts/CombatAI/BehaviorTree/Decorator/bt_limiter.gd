@icon("res://Art/MetaIcons/BehaviorTree/limiter.svg")
extends Decorator
class_name DecoratorLimiter

@onready var key = &"limiter_%s" % get_instance_id()

@export var max_count: int = 0
var current_count: int = 0

func tick(agent, blackboard):
	var current_count = blackboard.get(key)
	
	if current_count == null:
		current_count = 0
	
	if current_count <= max_count:
		blackboard.set(key, current_count + 1)
		return get_child(0).tick(agent, blackboard)
	else:
		return FAILED
