extends PanelContainer
class_name CellContainer

@onready var Value = $BoxContainer/Value
@onready var GoalMetadata = $BoxContainer/GoalMetadata

var goal_strings: Array = [&"DEFAULT", &"MOVE_HOLD", &"ELIMINATE", &"ESCORT"]
