@icon("res://Art/MetaIcons/BehaviorTree/category_decorator.svg")
extends BehaviorTreeNode
class_name Decorator

func _ready():
	if get_child_count() < 1:
		print("BehaviorTree Error: Decorator %s should have at least one child" % name)

# DO NOT CHANGE THIS SCRIPT. GO TO INSPECTOR SCRIPT -> EXTEND SCRIPT
