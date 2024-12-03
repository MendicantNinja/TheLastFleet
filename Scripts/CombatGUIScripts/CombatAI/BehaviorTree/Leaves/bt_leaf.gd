@icon("res://Art/MetaIcons/BehaviorTree/action.svg")
extends BehaviorTreeNode
class_name Leaf

func _ready():
	if get_child_count() != 0:
		print("BehaviorTree Error: Leaf %s should not have children" % name)

# DO NOT CHANGE THIS SCRIPT. GO TO INSPECTOR SCRIPT -> EXTEND SCRIPT
