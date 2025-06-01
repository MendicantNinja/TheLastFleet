@icon("res://Art/MetaIcons/BehaviorTree/inverter.svg")
extends Decorator
class_name DecoratorInverter

func tick(action, blackboard):
	for c in get_children():
		var response: int = c.tick(action, blackboard)
		
		if response == SUCCESS:
			return FAILURE
		elif response == FAILURE:
			return SUCCESS
		
		return RUNNING
