extends RefCounted
class_name Blackboard

var blackboard = {}

func set_data(key, value: Variant, blackboard_name = &"default") -> void:
	if not blackboard.has(blackboard_name):
		blackboard[blackboard_name] = {}
	
	blackboard[blackboard_name][key] = value

func ret_data(key, default_value = null, blackboard_name = &"default") -> Variant:
	if has_data(key, blackboard_name):
		return blackboard[blackboard_name][key]
	return default_value

func has_data(key, blackboard_name = &"default"):
	return blackboard.has(blackboard_name) and blackboard[blackboard_name].has(key) and blackboard[blackboard_name][key] != null

func remove_data(key, blackboard_name = &"default") -> void:
	if blackboard.has(blackboard_name):
		blackboard[blackboard_name].erase(key)
