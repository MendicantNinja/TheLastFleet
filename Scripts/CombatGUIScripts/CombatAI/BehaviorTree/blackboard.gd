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
	if has_data(key):
		blackboard[blackboard_name].erase(key)

func _on_target_destroyed(target, target_group_key: StringName, target_key: StringName) -> void:
	if not has_data(target_group_key):
		assert(has_data(target_group_key), "Something removed target group key from the blackboard.")
	
	if not has_data(target_key):
		assert(has_data(target_group_key), "Something removed target key from the blackboard.")
	
	if ret_data(target_key) == target:
		remove_data(target_key)
	
	var available_targets: Array = ret_data(target_group_key)
	available_targets.erase(target)
	if available_targets.is_empty():
		remove_data(target_group_key)
		return
	
	set_data(target_group_key, available_targets)
