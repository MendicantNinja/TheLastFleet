@icon("res://Art/MetaIcons/BehaviorTree/succeed.svg")
extends Decorator
class_name DecoratorSucceeder

func tick(action, blackboard):
	for c in get_children():
		var response: int = c.tick(action, blackboard)
		
		if response == RUNNING:
			return RUNNING
		
		return SUCCESS
