@icon("res://Art/MetaIcons/BehaviorTree/sequencer.svg")
extends GodotComposite
class_name CompositeSequence

func tick(agent, blackboard):
	for c in get_children():
		var response: int = c.tick(agent, blackboard)
		
		if response != SUCCESS:
			return response
	
	return SUCCESS
