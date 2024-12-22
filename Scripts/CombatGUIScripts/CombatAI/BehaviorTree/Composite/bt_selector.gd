@icon("res://Art/MetaIcons/BehaviorTree/selector.svg")
extends Composite
class_name CompositeSelector

func tick(agent, blackboard):
	for c in get_children():
		var response: int = c.tick(agent, blackboard)
		
		if response != FAILURE:
			return response
	
	return FAILURE
