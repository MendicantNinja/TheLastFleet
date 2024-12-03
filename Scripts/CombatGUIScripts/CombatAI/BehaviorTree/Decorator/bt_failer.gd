@icon("res://Art/MetaIcons/BehaviorTree/fail.svg")
extends Decorator
class_name DecoratorFailer

func tick(action, blackboard):
	for c in get_children():
		var response: int = c.tick(action, blackboard)
		
		if response == RUNNING:
			return RUNNING
		
		return FAILURE
